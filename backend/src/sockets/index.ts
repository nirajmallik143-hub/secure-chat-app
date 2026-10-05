import { Server } from 'socket.io';
import http from 'http';
import { z } from 'zod';
import { env } from '../config/env';
import { prisma } from '../db';
import { verifyAccessToken } from '../utils/tokens';
import { emitToUser, setIO } from './hub';

const messageSchema = z.object({ to: z.string().uuid(), text: z.string().trim().min(1).max(2000) });

type Ack = ((result: unknown) => void) | undefined;

async function handleMessage(userId: string, to: string, text: string, ack: Ack) {
  if (!(await prisma.user.findUnique({ where: { id: to } }))) return ack?.({ error: 'not found' });
  const blocked = await prisma.block.findFirst({
    where: {
      OR: [
        { blockerId: to, blockedId: userId },
        { blockerId: userId, blockedId: to },
      ],
    },
  });
  if (blocked) return ack?.({ error: 'blocked' });
  const msg = await prisma.message.create({ data: { senderId: userId, receiverId: to, text } });
  emitToUser(to, 'message', msg);
  ack?.({ message: msg });
}

export function attachSockets(server: http.Server): Server {
  const io = new Server(server, { cors: { origin: env.corsOrigins.length ? env.corsOrigins : false } });
  setIO(io);

  io.use((socket, next) => {
    try {
      socket.data.userId = verifyAccessToken(String(socket.handshake.auth?.token ?? ''));
      next();
    } catch {
      next(new Error('unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    const userId: string = socket.data.userId;
    socket.join(`user:${userId}`);

    socket.on('message', async (raw, ack: Ack) => {
      const parsed = messageSchema.safeParse(raw);
      if (!parsed.success) return ack?.({ error: 'invalid message' });
      try {
        await handleMessage(userId, parsed.data.to, parsed.data.text, ack);
      } catch {
        ack?.({ error: 'failed' });
      }
    });
  });
  return io;
}
