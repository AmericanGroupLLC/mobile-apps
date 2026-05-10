const express = require('express');
const db = require('../db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

// Heuristic readiness scorer.
// Inputs (all optional): HRV (ms, higher is better), sleep hours (target ~8),
// recent workout strain (workout_minutes in last 24h).
// Output: integer 0–100 + a one-line suggestion.
function scoreReadiness({ hrvAvg, sleepHrs, workoutMinutes }) {
  let score = 50; // baseline
  if (hrvAvg != null) {
    // 30 ms is poor, 80+ ms is excellent.
    const hrvNorm = Math.max(0, Math.min(1, (hrvAvg - 30) / 50));
    score += hrvNorm * 25;
  }
  if (sleepHrs != null) {
    // 8 hours is the sweet spot; <5 is bad; >9 is also off.
    const ideal = 8;
    const delta = Math.abs(sleepHrs - ideal);
    const sleepNorm = Math.max(0, 1 - delta / 4);
    score += sleepNorm * 20;
  }
  if (workoutMinutes != null) {
    // Light recent training (~30 min) is fine; >120 min in 24h is heavy strain.
    if (workoutMinutes > 120) score -= Math.min(20, (workoutMinutes - 120) / 6);
  }
  score = Math.round(Math.max(0, Math.min(100, score)));

  let suggestion;
  if (score >= 80) suggestion = 'Green light — go push it 💪';
  else if (score >= 60) suggestion = 'Solid day — moderate effort recommended';
  else if (score >= 40) suggestion = 'Mixed signals — keep it easy today';
  else suggestion = 'Recovery day — prioritize sleep & gentle movement 🧘';

  return { score, suggestion };
}

// GET /api/insights/readiness — last-24h HRV + sleep_hrs + workout_minutes
router.get('/readiness', authRequired, (req, res) => {
  const userId = req.user.sub;

  const avg = (type) =>
    db
      .prepare(
        `SELECT AVG(value) AS v FROM metrics
         WHERE user_id = ? AND type = ?
           AND recorded_at >= datetime('now', '-1 day')`
      )
      .get(userId, type)?.v ?? null;

  const sum = (type) =>
    db
      .prepare(
        `SELECT SUM(value) AS v FROM metrics
         WHERE user_id = ? AND type = ?
           AND recorded_at >= datetime('now', '-1 day')`
      )
      .get(userId, type)?.v ?? null;

  const hrvAvg = avg('hrv_sdnn');
  const sleepHrs = sum('sleep_hrs');
  const workoutMinutes = sum('workout_minutes');

  const { score, suggestion } = scoreReadiness({ hrvAvg, sleepHrs, workoutMinutes });

  res.json({
    score,
    suggestion,
    hrv_avg: hrvAvg,
    sleep_hrs: sleepHrs,
    workout_minutes: workoutMinutes,
  });
});

// GET /api/insights/weekly — last-7-day per-day totals/averages per metric type
router.get('/weekly', authRequired, (req, res) => {
  const userId = req.user.sub;
  const rows = db
    .prepare(
      `SELECT
         type,
         date(recorded_at) AS day,
         SUM(value) AS total,
         AVG(value) AS avg,
         COUNT(*) AS count
       FROM metrics
       WHERE user_id = ?
         AND recorded_at >= datetime('now', '-7 day')
       GROUP BY type, date(recorded_at)
       ORDER BY day DESC, type`
    )
    .all(userId);

  res.json({ aggregates: rows });
});

module.exports = router;
