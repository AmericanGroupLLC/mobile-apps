// Auto-mock @react-native-async-storage/async-storage so auth.js + Guest
// Mode flow can run under Jest without a native module attached.
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock')
);

// Silence console noise in tests.
global.__reanimatedWorkletInit = jest.fn();
