import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { env } from '../config/env';
import { prisma } from '../db';
import { requireAuth } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { HttpError } from '../utils/errors';
import { answer } from '../services/tutor';

export const tutorRouter = Router();
tutorRouter.use(requireAuth);

const askSchema = z.object({ question: z.string().trim().min(2).max(1000) });
const knowledgeSchema = z.object({
  title: z.string().trim().min(2).max(200),
  content: z.string().trim().min(2).max(10000),
  subject: z.string().trim().max(60).optional(),
  grade: z.string().trim().max(30).optional(),
  language: z.enum(['en', 'ne']).default('ne'),
});

async function requireAdmin(userId: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user?.email || !env.adminEmails.includes(user.email.toLowerCase())) {
    throw new HttpError(403, 'Admin only');
  }
}

tutorRouter.post(
  '/ask',
  rateLimit({ windowMs: 60_000, limit: 10, standardHeaders: true, legacyHeaders: false, keyGenerator: (req) => req.userId ?? 'anon' }),
  validate(askSchema),
  async (req, res) => {
    try {
      res.json(await answer(req.body.question));
    } catch (e) {
      console.error(e);
      throw new HttpError(502, 'The tutor is unavailable right now');
    }
  },
);

// Training: admins add course notes, Q&A and syllabus content the tutor uses to answer.
tutorRouter.get('/knowledge', async (req, res) => {
  await requireAdmin(req.userId!);
  res.json({ entries: await prisma.knowledgeEntry.findMany({ orderBy: { createdAt: 'desc' }, take: 200 }) });
});

tutorRouter.post('/knowledge', validate(knowledgeSchema), async (req, res) => {
  await requireAdmin(req.userId!);
  const entry = await prisma.knowledgeEntry.create({ data: {
      title: req.body.title,
      content: req.body.content,
      subject: req.body.subject,
      grade: req.body.grade,
      language: req.body.language,
      createdBy: req.userId!,
    },
  });
  res.status(201).json({ entry });
});

tutorRouter.delete('/knowledge/:id', async (req, res) => {
  await requireAdmin(req.userId!);
  await prisma.knowledgeEntry.delete({ where: { id: req.params.id } });
  res.status(204).end();
});
