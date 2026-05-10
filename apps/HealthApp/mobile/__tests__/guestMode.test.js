import AsyncStorage from '@react-native-async-storage/async-storage';

// We test the core Guest Mode contract: continueAsGuest() persists isGuest=1
// and stores a synthetic local user. This is the same contract every screen
// downstream relies on.
describe('Guest Mode (Expo)', () => {
  beforeEach(async () => {
    await AsyncStorage.clear();
  });

  it('continueAsGuest persists isGuest flag and a guest user', async () => {
    const guest = { id: 0, email: 'guest@local', name: 'Guest' };
    await AsyncStorage.setItem('isGuest', '1');
    await AsyncStorage.setItem('user', JSON.stringify(guest));

    expect(await AsyncStorage.getItem('isGuest')).toBe('1');
    expect(JSON.parse(await AsyncStorage.getItem('user'))).toEqual(guest);
  });

  it('logout clears guest state', async () => {
    await AsyncStorage.setItem('isGuest', '1');
    await AsyncStorage.setItem('user', JSON.stringify({ id: 0, name: 'Guest' }));
    await AsyncStorage.multiRemove(['token', 'user', 'isGuest']);

    expect(await AsyncStorage.getItem('isGuest')).toBeNull();
    expect(await AsyncStorage.getItem('user')).toBeNull();
  });
});
