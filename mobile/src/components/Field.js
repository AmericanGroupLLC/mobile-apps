import React from 'react';
import { TextInput, View, Text } from 'react-native';
import { theme } from '../theme';

export function Field({ label, value, onChangeText, placeholder, secureTextEntry, keyboardType, autoCapitalize = 'none' }) {
  return (
    <View style={{ marginBottom: 14 }}>
      {label ? (
        <Text style={{ marginBottom: 6, color: theme.colors.muted, fontWeight: '600', fontSize: 13 }}>
          {label}
        </Text>
      ) : null}
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        secureTextEntry={secureTextEntry}
        keyboardType={keyboardType}
        autoCapitalize={autoCapitalize}
        placeholderTextColor="#9ca3af"
        style={{
          backgroundColor: theme.colors.bgAlt,
          borderRadius: theme.radius.md,
          paddingHorizontal: 14,
          paddingVertical: 12,
          fontSize: 16,
          color: theme.colors.text,
          borderWidth: 1,
          borderColor: theme.colors.border,
        }}
      />
    </View>
  );
}
