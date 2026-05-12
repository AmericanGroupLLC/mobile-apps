const request = require('supertest');
const path = require('path');
const fs = require('fs');
const os = require('os');

const tmpDb = path.join(os.tmpdir(), `myhealth-careplus-${Date.now()}.db`);
process.env.DB_PATH = tmpDb;
process.env.JWT_SECRET = 'jest-careplus-secret';

const app = require('../server.js')._app;

afterAll(() => { try { fs.unlinkSync(tmpDb); } catch {} });

describe('Care+ v1 routes', () => {

  test('GET /api/vendor/menu returns sample vendors filtered by condition', async () => {
    const all = await request(app).get('/api/vendor/menu');
    expect(all.status).toBe(200);
    expect(Array.isArray(all.body.vendors)).toBe(true);
    expect(all.body.vendors.length).toBeGreaterThanOrEqual(6);

    const filtered = await request(app).get('/api/vendor/menu?conditions=hypertension');
    expect(filtered.status).toBe(200);
    // Every returned vendor should either match the condition or always-on ('none').
    for (const v of filtered.body.vendors) {
      expect(
        v.supports_conditions.includes('hypertension') ||
        v.supports_conditions.includes('none')
      ).toBe(true);
    }
  });

  test('POST /api/insurance requires auth', async () => {
    const res = await request(app).post('/api/insurance').send({ payer: 'X' });
    expect(res.status).toBe(401);
  });

  test('GET /api/fhir/Patient without token returns 401', async () => {
    const res = await request(app).get('/api/fhir/Patient/123')
      .set('X-FHIR-Issuer', 'https://example.test');
    // Without the user-auth Bearer this is rejected by the auth middleware.
    expect([401, 403]).toContain(res.status);
  });

  test('GET /api/doctors/search rejects non-5-digit ZIP', async () => {
    const res = await request(app).get('/api/doctors/search?zip=abc');
    expect(res.status).toBe(400);
  });

  test('audit_log table exists and accepts NULL user_id', async () => {
    // Indirect: hit a public route mounted behind auditLog and verify the
    // audit row was written.
    const res = await request(app).get('/api/vendor/menu');
    expect(res.status).toBe(200);
    // Allow async write to settle.
    await new Promise(r => setTimeout(r, 50));
    const Database = require('better-sqlite3');
    const db = new Database(tmpDb);
    const row = db.prepare(
      `SELECT method, path, status FROM audit_log
        WHERE path LIKE '/api/vendor/menu%'
        ORDER BY id DESC LIMIT 1`
    ).get();
    db.close();
    expect(row).toBeDefined();
    expect(row.method).toBe('GET');
    expect(row.status).toBe(200);
  });
});
