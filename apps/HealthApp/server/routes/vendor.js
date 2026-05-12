'use strict';

const express = require('express');
const router = express.Router();

// Care+ v1 vendor stub.
//
// Real meal-vendor integration (Sun Basket / Trifecta / Factor / TBD) is
// blocked on vendor account approval. Week 1 ships these 6 sample
// vendors so the iOS / Android Diet → Vendor browse screens render
// real-shape data. Filtering by HealthCondition.rawValue values mirrors
// the on-device taxonomy in `shared/.../Health/HealthConditions.swift`.

const SAMPLE_VENDORS = [
  {
    id: 'sample-greenleaf',
    name: 'Greenleaf Kitchen',
    cuisine: 'Mediterranean',
    calories_per_meal_avg: 540,
    supports_conditions: ['hypertension', 'diabetesT2', 'obesity', 'heartCondition'],
    blurb: 'Olive-oil-forward, low-sodium, vegetable-led plates.',
  },
  {
    id: 'sample-protein-pantry',
    name: 'Protein Pantry',
    cuisine: 'High-protein',
    calories_per_meal_avg: 620,
    supports_conditions: ['diabetesT1', 'diabetesT2', 'obesity'],
    blurb: '40g+ protein per meal. Tracks net carbs.',
  },
  {
    id: 'sample-cardio-clean',
    name: 'CardioClean',
    cuisine: 'DASH-friendly',
    calories_per_meal_avg: 480,
    supports_conditions: ['hypertension', 'heartCondition', 'lowBloodPressure'],
    blurb: 'DASH-style plates. < 600 mg sodium per serving.',
  },
  {
    id: 'sample-renalbalance',
    name: 'Renal Balance',
    cuisine: 'Low-K / low-P',
    calories_per_meal_avg: 510,
    supports_conditions: ['kidneyIssue'],
    blurb: 'Low potassium + phosphorus for CKD diets.',
  },
  {
    id: 'sample-ironkitchen',
    name: 'Iron Kitchen',
    cuisine: 'Iron-forward',
    calories_per_meal_avg: 560,
    supports_conditions: ['anemia', 'pregnancy'],
    blurb: 'Iron-rich and folate-rich plates with vit-C pairings.',
  },
  {
    id: 'sample-everyday',
    name: 'Everyday Eats',
    cuisine: 'Family classics',
    calories_per_meal_avg: 590,
    supports_conditions: ['none'],
    blurb: 'No-fuss family meals. Always available.',
  },
];

router.get('/menu', (req, res) => {
  const conditionsParam = (req.query.conditions || '').toString();
  const wanted = conditionsParam
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
  let vendors;
  if (wanted.length === 0) {
    vendors = SAMPLE_VENDORS;
  } else {
    vendors = SAMPLE_VENDORS.filter(
      (v) =>
        v.supports_conditions.some((c) => wanted.includes(c)) ||
        v.supports_conditions.includes('none')
    );
  }
  res.json({ vendors });
});

module.exports = router;
