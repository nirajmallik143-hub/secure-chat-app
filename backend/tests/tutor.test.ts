import request from 'supertest';
import { bearer, db, resetDb } from './mockDb';

jest.mock('../src/db', () => ({ prisma: require('./mockDb').db }));
jest.mock('../src/config/env', () => {
  const actual = jest.requireActual('../src/config/env');
  return { env: { ...actual.env, adminEmails: ['admin@example.com'] } };
});

import { createApp } from '../src/app';
import { rank, setLlm } from '../src/services/tutor';

const app = createApp();
beforeEach(() => {
  resetDb();
  setLlm(undefined);
});

async function signup(email: string) {
  const res = await request(app).post('/api/auth/signup').send({ email, password: 'password123', displayName: 'S' });
  return res.body.accessToken as string;
}

describe('tutor', () => {
  it('ranks Nepali and English notes', () => {
    const entries = [
      { id: '1', title: 'नेपालको राजधानी', content: 'काठमाडौँ नेपालको राजधानी हो।' },
      { id: '2', title: 'Photosynthesis', content: 'Plants make food using sunlight.' },
    ];
    expect(rank('नेपालको राजधानी के हो', entries)[0].id).toBe('1');
    expect(rank('what is photosynthesis', entries)[0].id).toBe('2');
  });

  it('only admins can train the tutor', async () => {
    const user = await signup('student@example.com');
    const res = await request(app)
      .post('/api/tutor/knowledge')
      .set('Authorization', bearer(user))
      .send({ title: 'Gravity', content: 'Force of attraction' });
    expect(res.status).toBe(403);
  });

  it('answers from the trained knowledge base', async () => {
    const admin = await signup('admin@example.com');
    const add = await request(app)
      .post('/api/tutor/knowledge')
      .set('Authorization', bearer(admin))
      .send({ title: 'Gravity', content: 'Gravity is the force of attraction between masses.', language: 'en' });
    expect(add.status).toBe(201);
    const res = await request(app).post('/api/tutor/ask').set('Authorization', bearer(admin)).send({ question: 'What is gravity?' });
    expect(res.status).toBe(200);
    expect(res.body.answer).toContain('force of attraction');
    expect(res.body.sources[0].title).toBe('Gravity');
    expect(db.knowledgeEntry.rows).toHaveLength(1);
  });

  it('uses the LLM with retrieved context when configured', async () => {
    const admin = await signup('admin@example.com');
    await request(app).post('/api/tutor/knowledge').set('Authorization', bearer(admin)).send({ title: 'Gravity', content: 'Attraction between masses' });
    const complete = jest.fn().mockResolvedValue('LLM answer');
    setLlm({ complete });
    const res = await request(app).post('/api/tutor/ask').set('Authorization', bearer(admin)).send({ question: 'explain gravity' });
    expect(res.body.answer).toBe('LLM answer');
    expect(complete.mock.calls[0][1]).toContain('Attraction between masses');
  });
});
