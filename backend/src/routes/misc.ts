import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { requireAuth } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { HttpError } from '../utils/errors';

export const miscRouter = Router();
miscRouter.use(requireAuth);

const reportSchema = z
  .object({
    reportedUserId: z.string().uuid().optional(),
    postId: z.string().uuid().optional(),
    reason: z.string().trim().min(3).max(500),
  })
  .refine((d) => d.reportedUserId || d.postId, { message: 'reportedUserId or postId is required' });

miscRouter.post('/reports', validate(reportSchema), async (req, res) => {
  const { reportedUserId, postId } = req.body;
  if (reportedUserId && !(await prisma.user.findUnique({ where: { id: reportedUserId } }))) {
    throw new HttpError(404, 'User not found');
  }
  if (postId && !(await prisma.post.findUnique({ where: { id: postId } }))) {
    throw new HttpError(404, 'Post not found');
  }
  const report = await prisma.report.create({ data: { reporterId: req.userId!, ...req.body } });
  res.status(201).json({ report });
});

miscRouter.get('/notifications', async (req, res) => {
  const notifications = await prisma.notification.findMany({
    where: { recipientId: req.userId! },
    orderBy: { createdAt: 'desc' },
    take: 50,
    include: { actor: { select: { id: true, displayName: true, avatarUrl: true } } },
  });
  res.json({ notifications });
});

miscRouter.post('/notifications/read', async (req, res) => {
  await prisma.notification.updateMany({ where: { recipientId: req.userId!, read: false }, data: { read: true } });
  res.status(204).end();
});

miscRouter.get('/messages/:userId', async (req, res) => {
  const me = req.userId!;
  const other = req.params.userId;
  const blocked = await prisma.block.findFirst({
    where: {
      OR: [
        { blockerId: me, blockedId: other },
        { blockerId: other, blockedId: me },
      ],
    },
  });
  if (blocked) throw new HttpError(403, 'Blocked');
  const messages = await prisma.message.findMany({
    where: {
      OR: [
        { senderId: me, receiverId: other },
        { senderId: other, receiverId: me },
      ],
    },
    orderBy: { createdAt: 'asc' },
    take: 200,
  });
  res.json({ messages });
});
