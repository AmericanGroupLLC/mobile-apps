import React from 'react';
import { Pressable, Text, ActivityIndicator, View } from 'react-native';
import { theme } from '../theme';

export function Button({ title, onPress, variant = 'primary', loading, style }) {
  const isPrimary = variant === 'primary';
  return (
    <Pressable
      onPress={onPress}
      disabled={loading}
      style={({ pressed }) => [
        {
          backgroundColor: isPrimary ? theme.colors.primary : 'transparent',
          borderWidth: isPrimary ? 0 : 1.5,
          borderColor: theme.colors.border,
          paddingVertical: 14,
          paddingHorizontal: 22,
          borderRadius: theme.radius.pill,
          alignItems: 'center',
          opacity: pressed ? 0.85 : 1,
        },
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={isPrimary ? '#fff' : theme.colors.primary} />
      ) : (
        <Text
          style={{
            color: isPrimary ? '#fff' : theme.colors.text,
            fontWeight: '700',
            fontSize: 15,
          }}
        >
          {title}
        </Text>
      )}
    </Pressable>
  );
}

export function Card({ children, style }) {
  return (
    <View
      style={[
        {
          backgroundColor: theme.colors.card,
          borderRadius: theme.radius.lg,
          padding: 18,
          borderWidth: 1,
          borderColor: theme.colors.border,
        },
        theme.shadow.card,
        style,
      ]}
    >
      {children}
    </View>
  );
}
