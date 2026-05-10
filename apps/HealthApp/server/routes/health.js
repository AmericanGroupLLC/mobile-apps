const express = require('express');

const router = express.Router();

// Simple in-memory cache to be polite to upstream APIs
const cache = new Map();
const TTL_MS = 10 * 60 * 1000; // 10 minutes

async function cachedFetch(url) {
  const hit = cache.get(url);
  if (hit && Date.now() - hit.t < TTL_MS) return hit.data;
  const r = await fetch(url, { headers: { 'User-Agent': 'HealthApp/1.0' } });
  if (!r.ok) throw new Error(`Upstream ${r.status}`);
  const data = await r.json();
  cache.set(url, { t: Date.now(), data });
  return data;
}

// GET /api/health/topics?age=30&sex=female
// Live data from health.gov MyHealthfinder (free, no API key)
router.get('/topics', async (req, res) => {
  try {
    const { age, sex, keyword } = req.query;
    const params = new URLSearchParams({ lang: 'en' });
    if (age) params.set('age', age);
    if (sex) params.set('sex', sex);
    if (keyword) params.set('keyword', keyword);
    const url = `https://health.gov/myhealthfinder/api/v3/myhealthfinder.json?${params}`;
    const data = await cachedFetch(url);

    const sections =
      data?.Result?.Resources?.all?.Resource ||
      data?.Result?.Resources?.Resource ||
      [];
    const topics = (Array.isArray(sections) ? sections : [sections]).map((r) => ({
      id: r.Id,
      title: r.Title,
      categories: r.Categories,
      url: r.AccessibleVersion || r.HealthfinderUrl,
      image: r.ImageUrl,
      lastUpdated: r.LastUpdate,
    }));
    res.json({ count: topics.length, topics });
  } catch (e) {
    res.status(502).json({ error: 'Failed to load health topics', detail: e.message });
  }
});

// GET /api/health/topic/:id  — full content for a single topic
router.get('/topic/:id', async (req, res) => {
  try {
    const url = `https://health.gov/myhealthfinder/api/v3/topicsearch.json?topicId=${encodeURIComponent(req.params.id)}&lang=en`;
    const data = await cachedFetch(url);
    res.json(data?.Result || {});
  } catch (e) {
    res.status(502).json({ error: 'Failed to load topic', detail: e.message });
  }
});

// GET /api/health/drug?name=ibuprofen  — Open FDA drug labels (free, no key)
router.get('/drug', async (req, res) => {
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
      warnings: r.warnings?.[0],
      dosage: r.dosage_and_administration?.[0],
    }));
    res.json({ query: name, results });
  } catch (e) {
    res.status(502).json({ error: 'Failed to search drugs', detail: e.message });
  }
});

module.exports = router;
