// Express 4 does not catch async errors; this patches it. Must load before routers.
import 'express-async-errors';
import cors from 'cors';
import express, { NextFunction, Request, Response } from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { ZodError } from 'zod';
import { env } from './config/env';
import { HttpError } from './utils/errors';
import { authRouter } from './routes/auth';
import { postsRouter } from './routes/posts';
import { usersRouter } from './routes/users';
import { miscRouter } from './routes/misc';
import { tutorRouter } from './routes/tutor';

export function createApp() {
  const app = express();
  app.set('trust proxy', 1);
  app.use(helmet());
  app.use(cors({ origin: env.corsOrigins.length ? env.corsOrigins : false }));
  app.use(express.json({ limit: '100kb' }));
  app.use(rateLimit({ windowMs: 60_000, limit: 300, standardHeaders: true, legacyHeaders: false }));

  app.get('/health', (_req, res) => res.json({ status: 'ok' }));
  app.use('/api/auth', authRouter);
  app.use('/api/posts', postsRouter);
  app.use('/api/users', usersRouter);
  app.use('/api/tutor', tutorRouter);
  app.use('/api', miscRouter);

  app.use((_req, _res, next) => next(new HttpError(404, 'Not found')));
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
    if (err instanceof ZodError) return res.status(400).json({ error: 'Invalid input' });
    if (err instanceof Error && err.name === 'MulterError') return res.status(400).json({ error: err.message });
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  });
  return app;
}
