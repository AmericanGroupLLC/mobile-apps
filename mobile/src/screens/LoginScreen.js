import React, { useState } from 'react';
import { View, Text, ScrollView, KeyboardAvoidingView, Platform, Alert } from 'react-native';
import { Field } from '../components/Field';
import { Button } from '../components/UI';
import { theme } from '../theme';
import { useAuth } from '../auth';

export default function LoginScreen({ navigation }) {
  const { login, continueAsGuest } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit() {
    if (!email || !password) return Alert.alert('Missing fields', 'Enter email & password');
    setLoading(true);
    try {
      await login(email.trim(), password);
    } catch (e) {
      Alert.alert('Login failed', e.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: theme.colors.bg }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView contentContainerStyle={{ padding: 24, paddingTop: 80 }}>
        <Text style={{ fontSize: 34, fontWeight: '800', color: theme.colors.text }}>
          Welcome back 💙
        </Text>
        <Text style={{ color: theme.colors.muted, marginTop: 6, marginBottom: 32 }}>
          Sign in or continue as a guest — no email required.
        </Text>

        <Field label="Email" value={email} onChangeText={setEmail} placeholder="you@example.com" keyboardType="email-address" />
        <Field label="Password" value={password} onChangeText={setPassword} placeholder="••••••••" secureTextEntry />

        <Button title="Sign In" onPress={onSubmit} loading={loading} />
        <View style={{ height: 12 }} />
        <Button
          title="Create an account"
          variant="ghost"
          onPress={() => navigation.navigate('Register')}
        />
        <View style={{ height: 12 }} />
        <Button
          title="Continue as Guest"
          variant="ghost"
          onPress={continueAsGuest}
        />
        <Text style={{ color: theme.colors.muted, marginTop: 12, fontSize: 12, textAlign: 'center' }}>
          Guest mode keeps everything on this device. Sign in later for cloud sync.
        </Text>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
