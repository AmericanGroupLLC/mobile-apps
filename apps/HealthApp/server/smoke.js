/**
 * MyHealth backend smoke test.
 *
 * Hits every public route with a freshly-registered test user and prints a
 * compact PASS/FAIL summary. Designed to be runnable on any machine that has
 * the server running locally:
 *
 *     # terminal 1
 *     cd server && cp .env.example .env && npm install && npm run dev
 *
 *     # terminal 2
 *     cd server && npm run smoke
 *
 * Exits 0 if all checks pass, 1 otherwise.
 */

const BASE = process.env.BASE || 'http://localhost:4000';
const email = `smoke+${Date.now()}@myhealth.test`;
const password = 'password123';
const name = 'Smoke Test';

const results = [];
function record(name, ok, detail) {
  results.push({ name, ok, detail });
  console.log(`${ok ? '✅' : '❌'} ${name}${detail ? ' — ' + detail : ''}`);
}

async function call(method, path, { token, body } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(BASE + path, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  let data = null;
  try { data = await res.json(); } catch {}
  return { status: res.status, data };
}

(async () => {
  try {
    // Liveness
    const live = await call('GET', '/api/health-check');
    record('GET /api/health-check', live.status === 200 && live.data?.ok === true,
           `status=${live.status}`);

    // Register
    const reg = await call('POST', '/api/auth/register',
                            { body: { name, email, password } });
    record('POST /api/auth/register', reg.status === 201 || reg.status === 200,
           `status=${reg.status}`);
    const token = reg.data?.token;
    if (!token) throw new Error('no token returned');

    // Profile
    const me = await call('GET', '/api/profile', { token });
    record('GET /api/profile', me.status === 200, `status=${me.status}`);

    // Metric log
    const m = await call('POST', '/api/profile/metrics',
                         { token, body: { type: 'water', value: 250, unit: 'ml' } });
    record('POST /api/profile/metrics', m.status === 201, `status=${m.status}`);

    // Meal log
    const meal = await call('POST', '/api/nutrition/meal',
                            { token, body: { name: 'Banana', kcal: 89, protein_g: 1, carbs_g: 23, fat_g: 0 } });
    record('POST /api/nutrition/meal', meal.status === 201, `status=${meal.status}`);

    // Today meals
    const today = await call('GET', '/api/nutrition/today', { token });
    record('GET /api/nutrition/today', today.status === 200 && Array.isArray(today.data?.meals),
           `meals=${today.data?.meals?.length ?? 'n/a'}`);

    // Readiness
    const r = await call('GET', '/api/insights/readiness', { token });
    record('GET /api/insights/readiness', r.status === 200, `score=${r.data?.score ?? 'n/a'}`);

    // Social — friend
    const f = await call('POST', '/api/social/friend',
                         { token, body: { name: 'Alex', handle: 'alex123' } });
    record('POST /api/social/friend', f.status === 201, `status=${f.status}`);

    const friends = await call('GET', '/api/social/friends', { token });
    record('GET /api/social/friends', friends.status === 200 && Array.isArray(friends.data?.friends),
           `count=${friends.data?.friends?.length ?? 'n/a'}`);

    // Social — challenge
    const ch = await call('POST', '/api/social/challenge', {
      token,
      body: {
        title: '10K Steps Week',
        kind: 'steps',
        starts_at: new Date().toISOString(),
        ends_at: new Date(Date.now() + 7 * 86400_000).toISOString(),
        target: 70000,
      }
    });
    record('POST /api/social/challenge', ch.status === 201, `id=${ch.data?.challenge?.id ?? 'n/a'}`);
    const challengeId = ch.data?.challenge?.id;

    if (challengeId) {
      const submit = await call('POST', '/api/social/leaderboard/score',
                                 { token, body: { challenge_id: challengeId, score: 12345 } });
      record('POST /api/social/leaderboard/score', submit.status === 204,
             `status=${submit.status}`);

      const lb = await call('GET', `/api/social/leaderboard?challenge=${challengeId}`,
                            { token });
      record('GET /api/social/leaderboard',
             lb.status === 200 && Array.isArray(lb.data?.entries) && lb.data.entries.length > 0,
             `entries=${lb.data?.entries?.length ?? 'n/a'}`);
    }

    // Medicine lookup (no auth required — works for guest users)
    const med = await call('GET', '/api/medicine/lookup?name=ibuprofen');
    record('GET /api/medicine/lookup',
           med.status === 200 && Array.isArray(med.data?.results),
           `results=${med.data?.count ?? 0}`);

    const failed = results.filter((r) => !r.ok);
    console.log(`\n${results.length - failed.length} / ${results.length} passed.`);
    process.exit(failed.length === 0 ? 0 : 1);
  } catch (err) {
    console.error('💥 Smoke test crashed:', err.message);
    process.exit(1);
  }
})();
