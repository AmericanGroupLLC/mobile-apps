const express = require('express');
const db = require('../db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

/* ─── Friends ────────────────────────────────────────────────────── */

router.post('/friend', authRequired, (req, res) => {
  const userId = req.user.sub;
  const { name, handle, record_id } = req.body || {};
  if (!name || !handle) {
    return res.status(400).json({ error: 'name and handle required' });
  }
  try {
    const result = db
      .prepare(
        'INSERT OR IGNORE INTO friends (user_id, name, handle, record_id) VALUES (?, ?, ?, ?)'
      )
      .run(userId, name, handle, record_id || null);
    const friend =
      result.lastInsertRowid > 0
        ? db.prepare('SELECT * FROM friends WHERE id = ?').get(result.lastInsertRowid)
        : db.prepare('SELECT * FROM friends WHERE user_id = ? AND handle = ?').get(userId, handle);
    res.status(201).json({ friend });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.get('/friends', authRequired, (req, res) => {
  const userId = req.user.sub;
  const friends = db
    .prepare('SELECT * FROM friends WHERE user_id = ? ORDER BY added_at DESC')
    .all(userId);
  res.json({ friends });
});

router.delete('/friend/:id', authRequired, (req, res) => {
  const userId = req.user.sub;
  db.prepare('DELETE FROM friends WHERE id = ? AND user_id = ?').run(req.params.id, userId);
  res.status(204).end();
});

/* ─── Challenges ─────────────────────────────────────────────────── */

router.post('/challenge', authRequired, (req, res) => {
  const userId = req.user.sub;
  const { title, kind, starts_at, ends_at, target } = req.body || {};
  if (!title || !kind || !starts_at || !ends_at) {
    return res.status(400).json({ error: 'title, kind, starts_at, ends_at required' });
  }
  const result = db
    .prepare(
      `INSERT INTO challenges (title, kind, starts_at, ends_at, target, created_by)
       VALUES (?, ?, ?, ?, ?, ?)`
    )
    .run(title, kind, starts_at, ends_at, target || 0, userId);
  // Creator auto-joins.
  db.prepare(
    'INSERT OR IGNORE INTO challenge_participants (challenge_id, user_id) VALUES (?, ?)'
  ).run(result.lastInsertRowid, userId);
  const challenge = db
    .prepare('SELECT * FROM challenges WHERE id = ?')
    .get(result.lastInsertRowid);
  res.status(201).json({ challenge });
});

router.get('/challenges', authRequired, (req, res) => {
  const userId = req.user.sub;
  const challenges = db
    .prepare(
      `SELECT c.*, EXISTS (
         SELECT 1 FROM challenge_participants p
         WHERE p.challenge_id = c.id AND p.user_id = ?
       ) AS joined
       FROM challenges c
       WHERE c.ends_at >= datetime('now')
       ORDER BY c.ends_at ASC`
    )
    .all(userId);
  res.json({ challenges });
});

router.post('/challenge/:id/join', authRequired, (req, res) => {
  const userId = req.user.sub;
  db.prepare(
    'INSERT OR IGNORE INTO challenge_participants (challenge_id, user_id) VALUES (?, ?)'
  ).run(req.params.id, userId);
  res.status(204).end();
});

/* ─── Leaderboard ────────────────────────────────────────────────── */

router.post('/leaderboard/score', authRequired, (req, res) => {
  const userId = req.user.sub;
  const { challenge_id, score } = req.body || {};
  if (!challenge_id || score == null) {
    return res.status(400).json({ error: 'challenge_id and score required' });
  }
  db.prepare(
    `INSERT INTO leaderboard_entries (challenge_id, user_id, score, updated_at)
     VALUES (?, ?, ?, datetime('now'))
     ON CONFLICT(challenge_id, user_id)
     DO UPDATE SET score = excluded.score, updated_at = datetime('now')`
  ).run(challenge_id, userId, score);
  res.status(204).end();
});

router.get('/leaderboard', authRequired, (req, res) => {
  const challengeId = parseInt(req.query.challenge, 10);
  if (!challengeId) {
    return res.status(400).json({ error: 'challenge query param required' });
  }
  const rows = db
    .prepare(
      `SELECT l.*, u.name, u.email
       FROM leaderboard_entries l
       JOIN users u ON u.id = l.user_id
       WHERE l.challenge_id = ?
       ORDER BY l.score DESC
       LIMIT 50`
    )
    .all(challengeId);
  res.json({ entries: rows });
});

module.exports = router;
