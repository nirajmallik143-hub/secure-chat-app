import request from 'supertest';
import { bearer, db, resetDb } from './mockDb';

jest.mock('../src/db', () => ({ prisma: require('./mockDb').db }));

import { createApp } from '../src/app';

const app = createApp();
const body = { email: 'Sita@Example.com', password: 'password123', displayName: 'Sita' };

beforeEach(resetDb);

describe('auth', () => {
  it('signs up, hashes the password and returns tokens', async () => {
    const res = await request(app).post('/api/auth/signup').send(body);
    expect(res.status).toBe(201);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
    expect(res.body.user.email).toBe('sita@example.com');
    expect(res.body.user.passwordHash).toBeUndefined();
    expect(db.user.rows[0].passwordHash).not.toBe(body.password);
  });

  it('rejects invalid input', async () => {
    const res = await request(app).post('/api/auth/signup').send({ email: 'x', password: 'short', displayName: '' });
    expect(res.status).toBe(400);
  });

  it('rejects duplicate accounts', async () => {
    await request(app).post('/api/auth/signup').send(body);
    const res = await request(app).post('/api/auth/signup').send(body);
    expect(res.status).toBe(409);
  });

  it('logs in with phone and rejects bad passwords', async () => {
    await request(app).post('/api/auth/signup').send({ phone: '+9779812345678', password: 'password123', displayName: 'Ram' });
    const ok = await request(app).post('/api/auth/login').send({ phone: '+9779812345678', password: 'password123' });
    expect(ok.status).toBe(200);
    const bad = await request(app).post('/api/auth/login').send({ phone: '+9779812345678', password: 'wrongpass1' });
    expect(bad.status).toBe(401);
  });

  it('rotates refresh tokens (single use)', async () => {
    const { body: s } = await request(app).post('/api/auth/signup').send(body);
    const r1 = await request(app).post('/api/auth/refresh').send({ refreshToken: s.refreshToken });
    expect(r1.status).toBe(200);
    const r2 = await request(app).post('/api/auth/refresh').send({ refreshToken: s.refreshToken });
    expect(r2.status).toBe(401);
  });

  it('deletes the account', async () => {
    const { body: s } = await request(app).post('/api/auth/signup').send(body);
    const res = await request(app).delete('/api/auth/account').set('Authorization', bearer(s.accessToken));
    expect(res.status).toBe(204);
    expect(db.user.rows).toHaveLength(0);
  });
});
