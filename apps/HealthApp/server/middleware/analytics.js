// Optional PostHog analytics middleware. Loads lazily and degrades to a
// graceful no-op when posthog-node is not installed OR POSTHOG_API_KEY is
// unset. Same shape as middleware/sentry.js.

let PostHogReal = null;
try {
  // eslint-disable-next-line global-require
  PostHogReal = require('posthog-node').PostHog;
} catch (_e) {
  PostHogReal = null;
}

let client = null;

function init({ release, environment = 'production' } = {}) {
  if (client) return;
  if (!PostHogReal) return;
  const key = process.env.POSTHOG_API_KEY;
  if (!key) return;
  client = new PostHogReal(key, {
    host: process.env.POSTHOG_HOST || 'https://eu.i.posthog.com',
    flushAt: 20,
    flushInterval: 10_000,
  });
  client.register({ release, environment, service: 'myhealth-server' });
  // eslint-disable-next-line no-console
  console.log('[posthog] initialized', release);
}

function track(distinctId, event, properties = {}) {
  if (!client) return;
  client.capture({ distinctId: distinctId || 'anon', event, properties });
}

async function shutdown() {
  if (client) await client.shutdown();
}

module.exports = { init, track, shutdown };
