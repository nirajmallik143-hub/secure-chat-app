import { Server } from 'socket.io';
import http from 'http';
import { z } from 'zod';
import { env } from '../config/env';
import { prisma } from '../db';
import { verifyAccessToken } from '../utils/tokens';
import { emitToUser, setIO } from './hub';

const messageSchema = z.object({ to: z.string().uuid(), text: z.string().trim().min(1).max(2000) });

export function attachSockets(server: http.Server): Server {
  const io = new Server(server, { cors: { origin: env.corsOrigin } });
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

    socket.on('message', async (raw, ack) => {
      const parsed = messageSchema.safeParse(raw);
      if (!parsed.success) return ack?.({ error: 'invalid message' });
      const { to, text } = parsed.data;
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
    });
  });
  return io;
}
