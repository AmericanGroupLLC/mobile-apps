// Privacy-first analytics wrapper for Expo. Mirrors iOS/Android contract.
import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY_ENABLED = 'analyticsEnabled';

let PostHogReal = null;
try {
  // eslint-disable-next-line global-require
  PostHogReal = require('posthog-react-native').PostHog;
} catch (_e) {
  PostHogReal = null;
}

let client = null;

export async function isEnabled() {
  return (await AsyncStorage.getItem(KEY_ENABLED)) === '1';
}
export async function setEnabled(value) {
  await AsyncStorage.setItem(KEY_ENABLED, value ? '1' : '0');
  if (!value && client) { client.optOut(); client = null; }
}

export async function bootstrapIfEnabled() {
  if (client) return;
  if (!PostHogReal) return;
  if (!(await isEnabled())) return;
  const key = process.env.EXPO_PUBLIC_POSTHOG_API_KEY;
  if (!key) return;
  client = new PostHogReal(key, {
    host: process.env.EXPO_PUBLIC_POSTHOG_HOST || 'https://eu.i.posthog.com',
    captureAppLifecycleEvents: true,
    enable: true,
    sendFeatureFlagEvent: false,
  });
}

export function track(event, properties) { if (client) client.capture(event, properties); }
export function screen(name, properties)  { if (client) client.screen(name, properties); }
export function identify(distinctId, props) { if (client) client.identify(distinctId, props); }
export function reset() { if (client) client.reset(); }

export const Events = {
  ONBOARDING_STARTED:   'onboarding_started',
  ONBOARDING_COMPLETED: 'onboarding_completed',
  GUEST_MODE_CHOSEN:    'guest_mode_chosen',
  SIGN_IN_COMPLETED:    'sign_in_completed',
  WORKOUT_STARTED:      'workout_started',
  MEAL_LOGGED:          'meal_logged',
  MEDICINE_ADDED:       'medicine_added',
};

export default { isEnabled, setEnabled, bootstrapIfEnabled, track, screen, identify, reset, Events };
