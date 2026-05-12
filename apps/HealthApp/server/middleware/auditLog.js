'use strict';

const db = require('../db');

/**
 * Audit logger middleware. Logs every request that passes through it to
 * the `audit_log` table — required for any route that reads or writes PHI
 * (FHIR proxy, insurance card, doctor finder favorites, RPE log,
 * MyChart issuer table).
 *
 * Usage:
 *   const auditLog = require('./middleware/auditLog');
 *   app.use('/api/fhir', auditLog, fhirRoutes);
 *
 * Behavior:
 *  - Records the request *after* the response is finished (uses res.on('finish'))
 *    so we capture the actual status code.
 *  - Resolves user id from `req.user.id` (set by the auth middleware) when
 *    present; otherwise NULL.
 *  - Failures are logged to console but never bubble up — auditing must
 *    not break the request itself. (We DO want eventual alerting on a
 *    failure rate spike — out of scope for week 1.)
 *
 * Schema (created in db.js):
 *   audit_log(id, user_id, method, path, status, ip, user_agent, created_at)
 */
function auditLog(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    try {
      db.prepare(
        `INSERT INTO audit_log (user_id, method, path, status, ip, user_agent, created_at)
         VALUES (?, ?, ?, ?, ?, ?, datetime('now'))`
      ).run(
        req.user && req.user.id ? req.user.id : null,
        req.method,
        req.originalUrl || req.url,
        res.statusCode,
        req.ip || (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || null,
        (req.headers['user-agent'] || '').slice(0, 255)
      );
    } catch (err) {
      console.warn('[audit_log] write failed:', err.message);
    }
    // Also log to stdout in dev so the test harness can grep for it.
    if (process.env.AUDIT_LOG_VERBOSE === '1') {
      const ms = Date.now() - start;
      console.log(
        `[audit] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${ms}ms) user=${
          req.user && req.user.id ? req.user.id : '-'
        }`
      );
    }
  });
  next();
}

module.exports = auditLog;
