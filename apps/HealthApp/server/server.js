require('dotenv').config();
const express = require('express');
const cors = require('cors');
const Sentry = require('./middleware/sentry');
const Analytics = require('./middleware/analytics');

const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const healthRoutes = require('./routes/health');
const nutritionRoutes = require('./routes/nutrition');
const insightsRoutes = require('./routes/insights');
const socialRoutes = require('./routes/social');
const medicineRoutes = require('./routes/medicine');

const app = express();

// Initialize Sentry as early as possible. No-op if SENTRY_DSN env var
// is unset, so local dev / CI smoke runs aren't affected.
Sentry.init({
  serviceName: 'myhealth-server',
  release: `MyHealth-Server@${require('./package.json').version}`,
});
Sentry.requestHandler(app);

// PostHog analytics — same opt-in pattern (no-op without POSTHOG_API_KEY).
Analytics.init({
  release: `MyHealth-Server@${require('./package.json').version}`,
});

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/api/health-check', (_req, res) =>
  res.json({ ok: true, service: 'MyHealth API', time: new Date().toISOString() })
);

app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/nutrition', nutritionRoutes);
app.use('/api/insights', insightsRoutes);
app.use('/api/social', socialRoutes);
app.use('/api/medicine', medicineRoutes);

// Sentry error handler MUST come before any other error middleware.
Sentry.errorHandler(app);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Server error' });
});

const PORT = process.env.PORT || 4000;

// Only start the HTTP listener when this file is the entrypoint (`node server.js`
// or `npm run dev`). Tests `require('./server.js')` and access `_app` directly.
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`✅ MyHealth API listening on http://localhost:${PORT}`);
  });
}

module.exports = { _app: app };
