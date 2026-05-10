import Constants from 'expo-constants';
import AsyncStorage from '@react-native-async-storage/async-storage';

const API_URL =
  Constants.expoConfig?.extra?.apiUrl ||
  Constants.manifest?.extra?.apiUrl ||
  'http://localhost:4000';

async function request(path, { method = 'GET', body, auth = true } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (auth) {
    const token = await AsyncStorage.getItem('token');
    if (token) headers.Authorization = `Bearer ${token}`;
  }
  const res = await fetch(`${API_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  let data = null;
  try {
    data = await res.json();
  } catch (_) {}
  if (!res.ok) {
    const msg = (data && data.error) || `Request failed (${res.status})`;
    throw new Error(msg);
  }
  return data;
}

export const api = {
  // Auth
  register: (payload) => request('/api/auth/register', { method: 'POST', body: payload, auth: false }),
  login: (payload) => request('/api/auth/login', { method: 'POST', body: payload, auth: false }),

  // Profile
  getProfile: () => request('/api/profile'),
  updateProfile: (payload) => request('/api/profile', { method: 'PUT', body: payload }),

  // Metrics
  listMetrics: (type) =>
    request(`/api/profile/metrics${type ? `?type=${encodeURIComponent(type)}` : ''}`),
  addMetric: (payload) =>
    request('/api/profile/metrics', { method: 'POST', body: payload }),

  // Public health data
  topics: ({ age, sex, keyword } = {}) => {
    const p = new URLSearchParams();
    if (age) p.set('age', age);
    if (sex) p.set('sex', sex);
    if (keyword) p.set('keyword', keyword);
    return request(`/api/health/topics?${p.toString()}`, { auth: false });
  },
  drug: (name) => request(`/api/health/drug?name=${encodeURIComponent(name)}`, { auth: false }),
};

export { API_URL };
