// Optional Sentry middleware. Loads the SDK lazily and degrades to a no-op
// when @sentry/node is not installed OR SENTRY_DSN env var is unset.
//
// Production deploy: `npm install @sentry/node` and set SENTRY_DSN.
// Local dev / CI smoke: no install needed; the no-op shim keeps the path open.

let SentryReal = null;
try {
  // eslint-disable-next-line global-require
  SentryReal = require('@sentry/node');
} catch (_e) {
  SentryReal = null;
}

let started = false;

function init({ serviceName, release, environment = 'production' } = {}) {
  if (started) return;
  if (!SentryReal) return;
  const dsn = process.env.SENTRY_DSN;
  if (!dsn) return;

  SentryReal.init({
    dsn,
    release,
    environment,
    serverName: serviceName,
    // Privacy: never collect PII; sample 100% errors but ZERO traces.
    tracesSampleRate: 0,
    sendDefaultPii: false,
    beforeSend(event) {
      if (event.user) event.user = { id: undefined };
      return event;
    },
  });
  started = true;
  // eslint-disable-next-line no-console
  console.log('[sentry] initialized for', serviceName, release);
}

function requestHandler(app) {
  if (started && SentryReal?.Handlers?.requestHandler) {
    app.use(SentryReal.Handlers.requestHandler());
  }
}

function errorHandler(app) {
  if (started && SentryReal?.Handlers?.errorHandler) {
    app.use(SentryReal.Handlers.errorHandler());
  }
}

function captureException(err) {
  if (started) SentryReal.captureException(err);
}

function captureMessage(msg, level = 'info') {
  if (started) SentryReal.captureMessage(msg, level);
}

module.exports = {
  init,
  requestHandler,
  errorHandler,
  captureException,
  captureMessage,
};
