import React, { useState } from 'react';
import { View, Text, ScrollView, KeyboardAvoidingView, Platform, Alert } from 'react-native';
import { Field } from '../components/Field';
import { Button } from '../components/UI';
import { theme } from '../theme';
import { useAuth } from '../auth';

export default function RegisterScreen({ navigation }) {
  const { register } = useAuth();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit() {
    if (!name || !email || !password) return Alert.alert('Missing fields', 'All fields are required.');
    if (password.length < 6) return Alert.alert('Weak password', 'Use 6+ characters.');
    setLoading(true);
    try {
      await register(name.trim(), email.trim(), password);
    } catch (e) {
      Alert.alert('Registration failed', e.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: theme.colors.bg }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView contentContainerStyle={{ padding: 24, paddingTop: 60 }}>
        <Text style={{ fontSize: 30, fontWeight: '800', color: theme.colors.text }}>
          Start your journey 🌱
        </Text>
        <Text style={{ color: theme.colors.muted, marginTop: 6, marginBottom: 28 }}>
          Create your free HealthApp account.
        </Text>

        <Field label="Name" value={name} onChangeText={setName} placeholder="Jane Doe" autoCapitalize="words" />
        <Field label="Email" value={email} onChangeText={setEmail} placeholder="you@example.com" keyboardType="email-address" />
        <Field label="Password" value={password} onChangeText={setPassword} placeholder="6+ characters" secureTextEntry />

        <Button title="Create Account" onPress={onSubmit} loading={loading} />
        <View style={{ height: 12 }} />
        <Button title="Back to sign in" variant="ghost" onPress={() => navigation.goBack()} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
