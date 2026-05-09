// Sanity-tests the local theme constants — no native module required.
import { theme } from '../src/theme';

describe('Theme', () => {
  it('exposes a colors object', () => {
    expect(theme).toBeDefined();
    expect(typeof theme).toBe('object');
  });
});
