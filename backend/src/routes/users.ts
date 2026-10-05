import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { requireAuth } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { HttpError } from '../utils/errors';
import { notify } from '../services/notify';

export const usersRouter = Router();
usersRouter.use(requireAuth);

const profileSchema = z.object({
  displayName: z.string().trim().min(1).max(60).optional(),
  bio: z.string().max(300).nullable().optional(),
  avatarUrl: z.string().url().refine((u) => /^https?:\/\//i.test(u), 'Must be http(s)').nullable().optional(),
  language: z.enum(['en', 'ne']).optional(),
});

const select = { id: true, displayName: true, bio: true, avatarUrl: true } as const;

usersRouter.get('/me', async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.userId! },
    select: { ...select, email: true, phone: true, language: true },
  });
  if (!user) throw new HttpError(404, 'User not found');
  res.json({ user });
});

usersRouter.patch('/me', validate(profileSchema), async (req, res) => {
  const user = await prisma.user.update({
    where: { id: req.userId! },
    data: req.body,
    select: { ...select, language: true },
  });
  res.json({ user });
});

usersRouter.get('/search', async (req, res) => {
  const q = String(req.query.q ?? '').trim();
  if (!q) return res.json({ users: [] });
  const users = await prisma.user.findMany({
    where: { displayName: { contains: q, mode: 'insensitive' }, id: { not: req.userId! } },
    select,
    take: 20,
  });
  res.json({ users });
});

usersRouter.get('/:id', async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.params.id },
    select: { ...select, _count: { select: { followers: true, following: true, posts: true } } },
  });
  if (!user) throw new HttpError(404, 'User not found');
  const follow = await prisma.follow.findUnique({
    where: { followerId_followingId: { followerId: req.userId!, followingId: user.id } },
  });
  res.json({ user, followedByMe: !!follow });
});

usersRouter.post('/:id/follow', async (req, res) => {
  if (req.params.id === req.userId) throw new HttpError(400, 'Cannot follow yourself');
  const target = await prisma.user.findUnique({ where: { id: req.params.id } });
  if (!target) throw new HttpError(404, 'User not found');
  const key = { followerId_followingId: { followerId: req.userId!, followingId: target.id } };
  if (await prisma.follow.findUnique({ where: key })) {
    await prisma.follow.delete({ where: key });
    return res.json({ following: false });
  }
  await prisma.follow.create({ data: { followerId: req.userId!, followingId: target.id } });
  await notify(target.id, req.userId!, 'follow');
  res.json({ following: true });
});

usersRouter.post('/:id/block', async (req, res) => {
  if (req.params.id === req.userId) throw new HttpError(400, 'Cannot block yourself');
  const target = await prisma.user.findUnique({ where: { id: req.params.id } });
  if (!target) throw new HttpError(404, 'User not found');
  await prisma.block.upsert({
    where: { blockerId_blockedId: { blockerId: req.userId!, blockedId: target.id } },
    create: { blockerId: req.userId!, blockedId: target.id },
    update: {},
  });
  await prisma.follow.deleteMany({
    where: {
      OR: [
        { followerId: req.userId!, followingId: target.id },
        { followerId: target.id, followingId: req.userId! },
      ],
    },
  });
  res.status(204).end();
});

usersRouter.delete('/:id/block', async (req, res) => {
  await prisma.block.deleteMany({ where: { blockerId: req.userId!, blockedId: req.params.id } });
  res.status(204).end();
});
