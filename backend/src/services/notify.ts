import { prisma } from '../db';
import { emitToUser } from '../sockets/hub';

export async function notify(recipientId: string, actorId: string, type: string, refId?: string) {
  if (recipientId === actorId) return;
  const n = await prisma.notification.create({ data: { recipientId, actorId, type, refId } });
  emitToUser(recipientId, 'notification', n);
}
