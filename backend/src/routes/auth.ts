import { Router } from 'express';
import bcrypt from 'bcryptjs';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { prisma } from '../db';
import { validate } from '../middleware/validate';
import { requireAuth } from '../middleware/auth';
import { HttpError } from '../utils/errors';
import { hashToken, newRefreshToken, signAccessToken } from '../utils/tokens';

export const authRouter = Router();

const limiter = rateLimit({ windowMs: 15 * 60_000, limit: 30, standardHeaders: true, legacyHeaders: false });
authRouter.use(limiter);

const phone = z.string().regex(/^\+?[0-9]{7,15}$/, 'Invalid phone number');
const password = z.string().min(8, 'Password must be at least 8 characters').max(128);

const signupSchema = z
  .object({
    email: z.string().email().toLowerCase().optional(),
    phone: phone.optional(),
    password,
    displayName: z.string().trim().min(1).max(60),
  })
  .refine((d) => d.email || d.phone, { message: 'Email or phone is required' });

const loginSchema = z
  .object({ email: z.string().email().toLowerCase().optional(), phone: phone.optional(), password: z.string() })
  .refine((d) => d.email || d.phone, { message: 'Email or phone is required' });

const refreshSchema = z.object({ refreshToken: z.string().min(1) });

async function issueTokens(userId: string) {
  const rt = newRefreshToken();
  await prisma.refreshToken.create({ data: { tokenHash: rt.hash, userId, expiresAt: rt.expiresAt } });
  return { accessToken: signAccessToken(userId), refreshToken: rt.token };
}

export const publicUser = (u: { id: string; email: string | null; phone: string | null; displayName: string; bio: string | null; avatarUrl: string | null; language: string }) => ({
  id: u.id,
  email: u.email,
  phone: u.phone,
  displayName: u.displayName,
  bio: u.bio,
  avatarUrl: u.avatarUrl,
  language: u.language,
});

authRouter.post('/signup', validate(signupSchema), async (req, res) => {
  const { email, phone, password, displayName } = req.body;
  const existing = await prisma.user.findFirst({
    where: { OR: [...(email ? [{ email }] : []), ...(phone ? [{ phone }] : [])] },
  });
  if (existing) throw new HttpError(409, 'Account already exists');
  const passwordHash = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({ data: { email, phone, passwordHash, displayName } });
  res.status(201).json({ user: publicUser(user), ...(await issueTokens(user.id)) });
});

authRouter.post('/login', validate(loginSchema), async (req, res) => {
  const { email, phone, password } = req.body;
  const user = await prisma.user.findFirst({ where: email ? { email } : { phone } });
  const ok = user ? await bcrypt.compare(password, user.passwordHash) : false;
  if (!user || !ok) throw new HttpError(401, 'Invalid credentials');
  res.json({ user: publicUser(user), ...(await issueTokens(user.id)) });
});

// Rotating refresh tokens: each token is single use.
authRouter.post('/refresh', validate(refreshSchema), async (req, res) => {
  const hash = hashToken(req.body.refreshToken);
  const stored = await prisma.refreshToken.findUnique({ where: { tokenHash: hash } });
  if (!stored || stored.expiresAt < new Date()) throw new HttpError(401, 'Invalid refresh token');
  await prisma.refreshToken.delete({ where: { id: stored.id } });
  res.json(await issueTokens(stored.userId));
});

authRouter.post('/logout', validate(refreshSchema), async (req, res) => {
  await prisma.refreshToken.deleteMany({ where: { tokenHash: hashToken(req.body.refreshToken) } });
  res.status(204).end();
});

// Account deletion (required by Google Play and Apple).
authRouter.delete('/account', requireAuth, async (req, res) => {
  await prisma.user.delete({ where: { id: req.userId! } });
  res.status(204).end();
});
