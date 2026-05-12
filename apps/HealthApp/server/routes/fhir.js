'use strict';

const express = require('express');
const auth = require('../middleware/auth');
const router = express.Router();

// FHIR proxy for resources the client can't fetch directly because of
// CORS or because we want a server-side cache. Week 1 is intentionally
// **passthrough** — the client could call Epic directly. The proxy
// exists so every PHI read is captured by the auditLog middleware
// (mounted in server.js ahead of this router).
//
// Required header: `X-FHIR-Issuer` — the issuer base URL (e.g. Epic
// sandbox). Required: `Authorization: Bearer …` with the FHIR access
// token (same one stored on-device in the Keychain / EncryptedSharedPreferences).

const ALLOWED_RESOURCES = new Set([
  'Patient',
  'Condition',
  'MedicationStatement',
  'AllergyIntolerance',
  'Observation',
  'Encounter',
  'Immunization',
  'Appointment',
]);

router.use(auth);

router.get('/:resource/:id?', async (req, res) => {
  const { resource, id } = req.params;
  const issuer = req.header('X-FHIR-Issuer');
  if (!issuer) return res.status(400).json({ error: 'Missing X-FHIR-Issuer' });
  if (!ALLOWED_RESOURCES.has(resource)) {
    return res.status(400).json({ error: `Resource ${resource} not allowed` });
  }
  const auth = req.header('Authorization');
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing FHIR Bearer token' });
  }
  const base = issuer.replace(/\/$/, '');
  const url = id
    ? `${base}/api/FHIR/R4/${resource}/${encodeURIComponent(id)}`
    : `${base}/api/FHIR/R4/${resource}?${new URLSearchParams(req.query).toString()}`;

  try {
    const upstream = await fetch(url, {
      headers: { 'Authorization': auth, 'Accept': 'application/fhir+json' },
    });
    const text = await upstream.text();
    res.status(upstream.status)
      .type('application/fhir+json')
      .send(text);
  } catch (err) {
    console.warn('[fhir] upstream failed:', err.message);
    res.status(502).json({ error: 'FHIR upstream failed' });
  }
});

module.exports = router;
