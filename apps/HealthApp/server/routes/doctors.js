'use strict';

const express = require('express');
const router = express.Router();

// Doctor finder backed by the public NPPES (NPI Registry) API.
//   https://npiregistry.cms.hhs.gov/api/?...&version=2.1
// Free, no key, generous rate limits. Returns providers and orgs by
// city/state/postal_code/taxonomy. We surface the structured fields
// Care+ v1 needs: NPI, name, specialty (taxonomy), phone, address, zip.
//
// In v1.1 this route will be swapped to Ribbon Health (with a real API
// key + booking) without changing the iOS/Android client surface — they
// only know about the response shape we produce here.

router.get('/search', async (req, res) => {
  const zip = (req.query.zip || '').toString().trim();
  const specialty = (req.query.specialty || '').toString().trim();
  if (!/^\d{5}$/.test(zip)) {
    return res.status(400).json({ error: 'zip must be a 5-digit US ZIP code' });
  }
  const url = new URL('https://npiregistry.cms.hhs.gov/api/');
  url.searchParams.set('version', '2.1');
  url.searchParams.set('postal_code', zip);
  url.searchParams.set('limit', '20');
  if (specialty) url.searchParams.set('taxonomy_description', specialty);

  try {
    const upstream = await fetch(url.toString(), {
      headers: { 'User-Agent': 'MyHealth-CarePlus/1.0' },
    });
    if (!upstream.ok) {
      return res.status(502).json({ error: `NPPES upstream ${upstream.status}` });
    }
    const body = await upstream.json();
    const providers = (body.results || []).map(transform).filter(Boolean);
    res.json({ providers });
  } catch (err) {
    console.warn('[doctors] upstream failed:', err.message);
    res.status(502).json({ error: 'NPPES request failed' });
  }
});

function transform(r) {
  if (!r || !r.number) return null;
  const basic = r.basic || {};
  const name =
    basic.organization_name ||
    [basic.first_name, basic.last_name].filter(Boolean).join(' ') ||
    'Unknown';
  const taxonomy = (r.taxonomies || []).find((t) => t.primary) || (r.taxonomies || [])[0];
  const address = (r.addresses || []).find((a) => a.address_purpose === 'LOCATION')
    || (r.addresses || [])[0]
    || {};
  const addressLine = [
    address.address_1,
    address.address_2,
    address.city,
    address.state,
    address.postal_code ? address.postal_code.slice(0, 5) : null,
  ].filter(Boolean).join(', ');
  return {
    npi: String(r.number),
    name,
    specialty: taxonomy ? taxonomy.desc || null : null,
    phone: address.telephone_number || null,
    address_line: addressLine || null,
    zip: address.postal_code ? address.postal_code.slice(0, 5) : null,
  };
}

module.exports = router;
