const express = require('express');
const db = require('../db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

// POST /api/nutrition/meal — log a meal with macros
router.post('/meal', authRequired, (req, res) => {
  const userId = req.user.sub;
  const {
    name,
    kcal,
    protein_g = 0,
    carbs_g = 0,
    fat_g = 0,
    barcode = null,
  } = req.body || {};

  if (!name || kcal == null) {
    return res.status(400).json({ error: 'name and kcal required' });
  }

  const result = db
    .prepare(
      `INSERT INTO meals (user_id, name, kcal, protein_g, carbs_g, fat_g, barcode)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
    .run(userId, name, kcal, protein_g, carbs_g, fat_g, barcode);

  const meal = db
    .prepare('SELECT * FROM meals WHERE id = ?')
    .get(result.lastInsertRowid);

  res.status(201).json({ meal });
});

// GET /api/nutrition/today — today's meals + totals
router.get('/today', authRequired, (req, res) => {
  const userId = req.user.sub;
  const meals = db
    .prepare(
      `SELECT * FROM meals
       WHERE user_id = ?
         AND date(recorded_at) = date('now')
       ORDER BY recorded_at DESC`
    )
    .all(userId);

  const totals = meals.reduce(
    (acc, m) => ({
      kcal: acc.kcal + (m.kcal || 0),
      protein_g: acc.protein_g + (m.protein_g || 0),
      carbs_g: acc.carbs_g + (m.carbs_g || 0),
      fat_g: acc.fat_g + (m.fat_g || 0),
    }),
    { kcal: 0, protein_g: 0, carbs_g: 0, fat_g: 0 }
  );

  res.json({ meals, totals });
});

// DELETE /api/nutrition/meal/:id — undo a meal log
router.delete('/meal/:id', authRequired, (req, res) => {
  const userId = req.user.sub;
  const id = parseInt(req.params.id, 10);
  const result = db
    .prepare('DELETE FROM meals WHERE id = ? AND user_id = ?')
    .run(id, userId);
  res.json({ deleted: result.changes });
});

module.exports = router;
