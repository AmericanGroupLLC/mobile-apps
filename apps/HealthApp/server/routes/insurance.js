'use strict';

const express = require('express');
const db = require('../db');
const auth = require('../middleware/auth');
const router = express.Router();

router.use(auth);

// Care+ v1 — store the parsed insurance card fields server-side so the
// user gets them on every device. Raw OCR text is NEVER sent here; it
// stays on-device (iOS Keychain / Android EncryptedSharedPreferences).

router.post('/', (req, res) => {
  const { payer, member_id, group_no, bin, pcn, rx_grp } = req.body || {};
  try {
    const stmt = db.prepare(`
      INSERT INTO insurance_card (user_id, payer, member_id, group_no, bin, pcn, rx_grp)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);
    const info = stmt.run(req.user.id, payer || null, member_id || null,
                          group_no || null, bin || null, pcn || null, rx_grp || null);
    res.json({ id: info.lastInsertRowid });
  } catch (err) {
    console.warn('[insurance] insert failed:', err.message);
    res.status(500).json({ error: 'Insert failed' });
  }
});

router.get('/', (req, res) => {
  const row = db.prepare(`
    SELECT payer, member_id, group_no, bin, pcn, rx_grp, captured_at
      FROM insurance_card
     WHERE user_id = ?
     ORDER BY captured_at DESC
     LIMIT 1
  `).get(req.user.id);
  res.json({ card: row || null });
});

module.exports = router;
