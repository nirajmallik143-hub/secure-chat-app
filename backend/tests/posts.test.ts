import request from 'supertest';
import { bearer, db, resetDb } from './mockDb';

jest.mock('../src/db', () => ({ prisma: require('./mockDb').db }));

import { createApp } from '../src/app';

const app = createApp();

beforeEach(resetDb);

async function signup() {
  const res = await request(app)
    .post('/api/auth/signup')
    .send({ email: `u${db.user.rows.length}@example.com`, password: 'password123', displayName: 'U' });
  return res.body.accessToken as string;
}

describe('posts', () => {
  it('requires authentication', async () => {
    expect((await request(app).get('/api/posts')).status).toBe(401);
  });

  it('creates a post', async () => {
    const token = await signup();
    const res = await request(app).post('/api/posts').set('Authorization', bearer(token)).send({ text: 'नमस्ते Nepal' });
    expect(res.status).toBe(201);
    expect(db.post.rows).toHaveLength(1);
    expect(db.post.rows[0].text).toBe('नमस्ते Nepal');
  });

  it('validates post text', async () => {
    const token = await signup();
    const res = await request(app).post('/api/posts').set('Authorization', bearer(token)).send({ text: '   ' });
    expect(res.status).toBe(400);
  });

  it("forbids deleting someone else's post", async () => {
    const a = await signup();
    const b = await signup();
    const created = await request(app).post('/api/posts').set('Authorization', bearer(a)).send({ text: 'hi' });
    const res = await request(app).delete(`/api/posts/${created.body.post.id}`).set('Authorization', bearer(b));
    expect(res.status).toBe(403);
  });
});
