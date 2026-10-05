import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';

export function signAccessToken(userId: string): string {
  return jwt.sign({ sub: userId }, env.accessSecret, { expiresIn: 900 });
}

export function verifyAccessToken(token: string): string {
  const payload = jwt.verify(token, env.accessSecret) as jwt.JwtPayload;
  if (!payload.sub) throw new Error('invalid token');
  return payload.sub;
}

// Refresh tokens are random opaque values; only their SHA-256 hash is stored.
export function newRefreshToken(): { token: string; hash: string; expiresAt: Date } {
  const token = crypto.randomBytes(48).toString('hex');
  return {
    token,
    hash: hashToken(token),
    expiresAt: new Date(Date.now() + env.refreshTtlDays * 86400_000),
  };
}

export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}
