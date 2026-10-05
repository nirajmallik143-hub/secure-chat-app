import { Router } from 'express';
import multer from 'multer';
import { z } from 'zod';
import { prisma } from '../db';
import { requireAuth } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { HttpError } from '../utils/errors';
import { ALLOWED_IMAGE_TYPES, getStorage } from '../services/storage';
import { notify } from '../services/notify';

export const postsRouter = Router();
postsRouter.use(requireAuth);

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

const postSchema = z.object({
  text: z.string().trim().min(1).max(5000),
  imageUrl: z.string().url().optional(),
});
const commentSchema = z.object({ text: z.string().trim().min(1).max(2000) });

async function blockedIds(userId: string): Promise<string[]> {
  const rows = await prisma.block.findMany({
    where: { OR: [{ blockerId: userId }, { blockedId: userId }] },
  });
  return rows.map((b) => (b.blockerId === userId ? b.blockedId : b.blockerId));
}

postsRouter.post('/upload', upload.single('image'), async (req, res) => {
  const file = req.file;
  if (!file || !ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
    throw new HttpError(400, 'A JPEG, PNG or WebP image is required');
  }
  res.status(201).json({ url: await getStorage().upload(file.buffer, file.mimetype) });
});

postsRouter.get('/', async (req, res) => {
  const take = Math.min(Number(req.query.limit) || 20, 50);
  const cursor = typeof req.query.cursor === 'string' ? req.query.cursor : undefined;
  const hiddenAuthors = await blockedIds(req.userId!);
  const posts = await prisma.post.findMany({
    where: { hidden: false, authorId: { notIn: hiddenAuthors } },
    orderBy: { createdAt: 'desc' },
    take,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    include: {
      author: { select: { id: true, displayName: true, avatarUrl: true } },
      _count: { select: { likes: true, comments: true } },
      likes: { where: { userId: req.userId! }, select: { userId: true } },
    },
  });
  res.json({
    posts: posts.map(({ likes, ...p }) => ({ ...p, likedByMe: likes.length > 0 })),
    nextCursor: posts.length === take ? posts[posts.length - 1].id : null,
  });
});

postsRouter.post('/', validate(postSchema), async (req, res) => {
  const post = await prisma.post.create({
    data: { authorId: req.userId!, text: req.body.text, imageUrl: req.body.imageUrl },
  });
  res.status(201).json({ post });
});

postsRouter.delete('/:id', async (req, res) => {
  const post = await prisma.post.findUnique({ where: { id: req.params.id } });
  if (!post) throw new HttpError(404, 'Post not found');
  if (post.authorId !== req.userId) throw new HttpError(403, 'Forbidden');
  await prisma.post.delete({ where: { id: post.id } });
  res.status(204).end();
});

postsRouter.post('/:id/like', async (req, res) => {
  const post = await prisma.post.findUnique({ where: { id: req.params.id } });
  if (!post) throw new HttpError(404, 'Post not found');
  const key = { userId_postId: { userId: req.userId!, postId: post.id } };
  const existing = await prisma.like.findUnique({ where: key });
  if (existing) {
    await prisma.like.delete({ where: key });
    return res.json({ liked: false });
  }
  await prisma.like.create({ data: { userId: req.userId!, postId: post.id } });
  await notify(post.authorId, req.userId!, 'like', post.id);
  res.json({ liked: true });
});

postsRouter.get('/:id/comments', async (req, res) => {
  const hiddenAuthors = await blockedIds(req.userId!);
  const comments = await prisma.comment.findMany({
    where: { postId: req.params.id, authorId: { notIn: hiddenAuthors } },
    orderBy: { createdAt: 'asc' },
    include: { author: { select: { id: true, displayName: true, avatarUrl: true } } },
  });
  res.json({ comments });
});

postsRouter.post('/:id/comments', validate(commentSchema), async (req, res) => {
  const post = await prisma.post.findUnique({ where: { id: req.params.id } });
  if (!post) throw new HttpError(404, 'Post not found');
  const comment = await prisma.comment.create({
    data: { postId: post.id, authorId: req.userId!, text: req.body.text },
  });
  await notify(post.authorId, req.userId!, 'comment', post.id);
  res.status(201).json({ comment });
});
