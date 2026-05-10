// Privacy-first wrapper around sentry-expo. Mirrors the iOS/Android contract:
//   * Off by default; user must opt-in via Settings.
//   * DSN read from EXPO_PUBLIC_SENTRY_DSN (set at build time).
//   * No PII, no tracing, manual capture only.

import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY_ENABLED = 'crashReportsEnabled';

let Sentry = null;
try {
  // eslint-disable-next-line global-require
  Sentry = require('sentry-expo');
} catch (_e) {
  Sentry = null;
}

let started = false;

export async function isEnabled() {
  return (await AsyncStorage.getItem(KEY_ENABLED)) === '1';
}

export async function setEnabled(value) {
  await AsyncStorage.setItem(KEY_ENABLED, value ? '1' : '0');
  // We can't really stop sentry-expo at runtime; effective on next launch.
}

export async function bootstrapIfEnabled({ release, environment = 'production' } = {}) {
  if (started) return;
  if (!Sentry) return;
  if (!(await isEnabled())) return;
  const dsn = process.env.EXPO_PUBLIC_SENTRY_DSN;
  if (!dsn) return;

  Sentry.init({
    dsn,
    enableInExpoDevelopment: false,
    debug: false,
    release,
    environment,
    tracesSampleRate: 0,
    sendDefaultPii: false,
    beforeSend(event) {
      if (event.user) event.user = null;
      return event;
    },
  });
  started = true;
}

export function captureException(err) {
  if (started) Sentry.Native.captureException(err);
}
export function captureMessage(msg) {
  if (started) Sentry.Native.captureMessage(msg);
}

export default { isEnabled, setEnabled, bootstrapIfEnabled, captureException, captureMessage };
