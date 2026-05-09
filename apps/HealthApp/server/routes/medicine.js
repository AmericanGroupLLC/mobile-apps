const express = require('express');

const router = express.Router();

// Reuse the cache the health.js route uses (best-effort).
const cache = new Map();
const TTL_MS = 10 * 60 * 1000;

async function cachedFetch(url) {
  const hit = cache.get(url);
  if (hit && Date.now() - hit.t < TTL_MS) return hit.data;
  const r = await fetch(url, { headers: { 'User-Agent': 'MyHealth/1.0' } });
  if (!r.ok) throw new Error(`Upstream ${r.status}`);
  const data = await r.json();
  cache.set(url, { t: Date.now(), data });
  return data;
}

// GET /api/medicine/lookup?name=ibuprofen
// Public — no auth required so guest users can use this too.
router.get('/lookup', async (req, res) => {
  try {
    const name = (req.query.name || '').trim();
    if (!name) return res.status(400).json({ error: 'name required' });
    const url = `https://api.fda.gov/drug/label.json?search=openfda.brand_name:%22${encodeURIComponent(
      name
    )}%22+OR+openfda.generic_name:%22${encodeURIComponent(name)}%22&limit=5`;
    const data = await cachedFetch(url);
    const results = (data.results || []).map((r) => ({
      brand: r.openfda?.brand_name?.[0],
      generic: r.openfda?.generic_name?.[0],
      manufacturer: r.openfda?.manufacturer_name?.[0],
      purpose: r.purpose?.[0],
      indications: r.indications_and_usage?.[0],
      dosage: r.dosage_and_administration?.[0],
      warnings: r.warnings?.[0],
    }));
    res.json({ query: name, count: results.length, results });
  } catch (e) {
    res.status(502).json({ error: 'Failed to look up drug', detail: e.message });
  }
});

module.exports = router;
