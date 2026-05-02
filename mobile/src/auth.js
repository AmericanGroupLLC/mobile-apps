import React, { createContext, useContext, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { api } from './api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const cached = await AsyncStorage.getItem('user');
        if (cached) setUser(JSON.parse(cached));
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  async function persist(authResp) {
    await AsyncStorage.setItem('token', authResp.token);
    await AsyncStorage.setItem('user', JSON.stringify(authResp.user));
    setUser(authResp.user);
  }

  async function login(email, password) {
    const r = await api.login({ email, password });
    await persist(r);
  }

  async function register(name, email, password) {
    const r = await api.register({ name, email, password });
    await persist(r);
  }

  async function logout() {
    await AsyncStorage.multiRemove(['token', 'user', 'isGuest']);
    setUser(null);
  }

  /**
   * No-account path. Persists a synthetic local user so the rest of the app
   * (which gates on `user`) keeps working. Backend calls should check
   * `await AsyncStorage.getItem('isGuest')` and short-circuit.
   */
  async function continueAsGuest() {
    const guest = { id: 0, email: 'guest@local', name: 'Guest' };
    await AsyncStorage.setItem('isGuest', '1');
    await AsyncStorage.setItem('user', JSON.stringify(guest));
    setUser(guest);
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, continueAsGuest }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
