import { NextFunction, Request, Response } from 'express';
import { verifyAccessToken } from '../utils/tokens';
import { HttpError } from '../utils/errors';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

export function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return next(new HttpError(401, 'Missing token'));
  try {
    req.userId = verifyAccessToken(header.slice(7));
    next();
  } catch {
    next(new HttpError(401, 'Invalid or expired token'));
  }
}
