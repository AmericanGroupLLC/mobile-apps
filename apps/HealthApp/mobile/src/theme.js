export const theme = {
  colors: {
    bg: '#ffffff',
    bgAlt: '#f7f9fc',
    text: '#0f172a',
    muted: '#64748b',
    border: '#e5e7eb',
    primary: '#06b6d4',
    primaryDark: '#0891b2',
    accent: '#ec4899',
    purple: '#8b5cf6',
    success: '#10b981',
    danger: '#ef4444',
    card: '#ffffff',
  },
  radius: { sm: 8, md: 14, lg: 22, pill: 999 },
  spacing: (n) => n * 4,
  font: {
    h1: 28,
    h2: 22,
    h3: 18,
    body: 15,
    small: 13,
  },
  shadow: {
    card: {
      shadowColor: '#0f172a',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.08,
      shadowRadius: 12,
      elevation: 3,
    },
  },
};
