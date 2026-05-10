const express = require('express');
const db = require('../db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

// Helper: BMI + category
function bmiInfo(height_cm, weight_kg) {
  if (!height_cm || !weight_kg) return null;
  const h = height_cm / 100;
  const bmi = weight_kg / (h * h);
  let category = 'Unknown';
  if (bmi < 18.5) category = 'Underweight';
  else if (bmi < 25) category = 'Healthy';
  else if (bmi < 30) category = 'Overweight';
  else category = 'Obese';
  return { value: Math.round(bmi * 10) / 10, category };
}

// GET /api/profile  — current user's profile
router.get('/', authRequired, (req, res) => {
  const userId = req.user.sub;
  const user = db
    .prepare('SELECT id, email, name, created_at FROM users WHERE id = ?')
    .get(userId);
  const profile =
    db.prepare('SELECT * FROM profiles WHERE user_id = ?').get(userId) || {};
  res.json({
    user,
    profile,
    bmi: bmiInfo(profile.height_cm, profile.weight_kg),
  });
});

// PUT /api/profile  — upsert profile fields
router.put('/', authRequired, (req, res) => {
  const userId = req.user.sub;
  const { age, sex, height_cm, weight_kg, activity_level, goal } = req.body || {};

  const existing = db
    .prepare('SELECT user_id FROM profiles WHERE user_id = ?')
    .get(userId);

  if (existing) {
    db.prepare(
      `UPDATE profiles
       SET age = COALESCE(?, age),
           sex = COALESCE(?, sex),
           height_cm = COALESCE(?, height_cm),
           weight_kg = COALESCE(?, weight_kg),
           activity_level = COALESCE(?, activity_level),
           goal = COALESCE(?, goal),
           updated_at = datetime('now')
       WHERE user_id = ?`
    ).run(age, sex, height_cm, weight_kg, activity_level, goal, userId);
  } else {
    db.prepare(
      `INSERT INTO profiles
        (user_id, age, sex, height_cm, weight_kg, activity_level, goal)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    ).run(userId, age, sex, height_cm, weight_kg, activity_level, goal);
  }

  const profile = db
    .prepare('SELECT * FROM profiles WHERE user_id = ?')
    .get(userId);
  res.json({ profile, bmi: bmiInfo(profile.height_cm, profile.weight_kg) });
});

// POST /api/profile/metrics  — log a metric (weight, steps, hr, sleep_hrs, water_l)
router.post('/metrics', authRequired, (req, res) => {
  const userId = req.user.sub;
  const { type, value, unit } = req.body || {};
  if (!type || value == null)
    return res.status(400).json({ error: 'type and value required' });

  const result = db
    .prepare(
      'INSERT INTO metrics (user_id, type, value, unit) VALUES (?, ?, ?, ?)'
    )
    .run(userId, type, value, unit || null);

  const metric = db
    .prepare('SELECT * FROM metrics WHERE id = ?')
    .get(result.lastInsertRowid);
  res.status(201).json({ metric });
});

// GET /api/profile/metrics?type=weight&limit=30
router.get('/metrics', authRequired, (req, res) => {
  const userId = req.user.sub;
  const { type } = req.query;
  const limit = Math.min(parseInt(req.query.limit || '50', 10), 200);
  const rows = type
    ? db
        .prepare(
          'SELECT * FROM metrics WHERE user_id = ? AND type = ? ORDER BY recorded_at DESC LIMIT ?'
        )
        .all(userId, type, limit)
    : db
        .prepare(
          'SELECT * FROM metrics WHERE user_id = ? ORDER BY recorded_at DESC LIMIT ?'
        )
        .all(userId, limit);
  res.json({ metrics: rows });
});

module.exports = router;
