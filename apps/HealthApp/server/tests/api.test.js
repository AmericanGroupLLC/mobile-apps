const request = require('supertest');
const path = require('path');
const fs = require('fs');
const os = require('os');

// Use a fresh tmp DB per test run so we don't pollute the dev DB.
// Must be on a local filesystem (SQLite WAL doesn't work on network shares).
const tmpDb = path.join(os.tmpdir(), `myhealth-test-${Date.now()}.db`);
process.env.DB_PATH = tmpDb;
process.env.JWT_SECRET = 'jest-test-secret';

// Express app is created on require — env vars must be set first.
const app = require('../server.js')._app
  ?? require('express')(); // fallback if server.js exports the bare listener

afterAll(() => {
  try { fs.unlinkSync(tmpDb); } catch {}
});

describe('MyHealth API', () => {
  let token;

  it('GET /api/health-check returns ok', async () => {
    const res = await request(app).get('/api/health-check');
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
  });

  it('POST /api/auth/register creates user + returns token', async () => {
    const res = await request(app).post('/api/auth/register').send({
      name: 'Jest User',
      email: `jest-${Date.now()}@example.com`,
      password: 'password123',
    });
    expect([200, 201]).toContain(res.status);
    expect(res.body.token).toBeDefined();
    token = res.body.token;
  });

  it('GET /api/profile requires auth', async () => {
    const res = await request(app).get('/api/profile');
    expect(res.status).toBe(401);
  });

  it('POST /api/profile/metrics logs a metric', async () => {
    const res = await request(app)
      .post('/api/profile/metrics')
      .set('Authorization', `Bearer ${token}`)
      .send({ type: 'water', value: 250, unit: 'ml' });
    expect(res.status).toBe(201);
    expect(res.body.metric.value).toBe(250);
  });

  it('Social: friend → friends round-trip', async () => {
    await request(app)
      .post('/api/social/friend')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Sam', handle: 'sam' });
    const list = await request(app)
      .get('/api/social/friends')
      .set('Authorization', `Bearer ${token}`);
    expect(list.status).toBe(200);
    expect(list.body.friends.length).toBeGreaterThan(0);
  });

  it('Social: challenge + leaderboard submit + read', async () => {
    const challenge = await request(app)
      .post('/api/social/challenge')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Test Week',
        kind: 'steps',
        starts_at: new Date().toISOString(),
        ends_at: new Date(Date.now() + 7 * 86400_000).toISOString(),
        target: 70000,
      });
    expect(challenge.status).toBe(201);
    const id = challenge.body.challenge.id;

    const submit = await request(app)
      .post('/api/social/leaderboard/score')
      .set('Authorization', `Bearer ${token}`)
      .send({ challenge_id: id, score: 999 });
    expect(submit.status).toBe(204);

    const board = await request(app)
      .get(`/api/social/leaderboard?challenge=${id}`)
      .set('Authorization', `Bearer ${token}`);
    expect(board.status).toBe(200);
    expect(board.body.entries.length).toBeGreaterThan(0);
  });
});
