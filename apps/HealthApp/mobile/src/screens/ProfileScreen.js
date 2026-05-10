import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { Field } from '../components/Field';
import { Button, Card } from '../components/UI';
import { theme } from '../theme';
import { useAuth } from '../auth';
import { api } from '../api';

export default function ProfileScreen() {
  const { user, logout } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [bmi, setBmi] = useState(null);

  const [age, setAge] = useState('');
  const [sex, setSex] = useState('');
  const [heightCm, setHeightCm] = useState('');
  const [weightKg, setWeightKg] = useState('');
  const [activity, setActivity] = useState('');
  const [goal, setGoal] = useState('');

  useEffect(() => { (async () => {
    try {
      const r = await api.getProfile();
      const p = r.profile || {};
      setAge(p.age?.toString() || '');
      setSex(p.sex || '');
      setHeightCm(p.height_cm?.toString() || '');
      setWeightKg(p.weight_kg?.toString() || '');
      setActivity(p.activity_level || '');
      setGoal(p.goal || '');
      setBmi(r.bmi);
    } catch (e) {
      Alert.alert('Could not load profile', e.message);
    } finally {
      setLoading(false);
    }
  })(); }, []);

  async function onSave() {
    setSaving(true);
    try {
      const r = await api.updateProfile({
        age: age ? parseInt(age, 10) : null,
        sex: sex || null,
        height_cm: heightCm ? parseFloat(heightCm) : null,
        weight_kg: weightKg ? parseFloat(weightKg) : null,
        activity_level: activity || null,
        goal: goal || null,
      });
      setBmi(r.bmi);
      Alert.alert('Saved ✅', 'Profile updated.');
    } catch (e) {
      Alert.alert('Save failed', e.message);
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: theme.colors.bg }}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  return (
    <ScrollView style={{ flex: 1, backgroundColor: theme.colors.bg }} contentContainerStyle={{ padding: 20, paddingTop: 60 }}>
      <Text style={{ fontSize: 28, fontWeight: '800', color: theme.colors.text }}>Your Profile</Text>
      <Text style={{ color: theme.colors.muted, marginBottom: 16 }}>{user?.email}</Text>

      {bmi && (
        <Card style={{ marginBottom: 18 }}>
          <Text style={{ color: theme.colors.muted, fontSize: 12, fontWeight: '600', textTransform: 'uppercase' }}>
            Body Mass Index
          </Text>
          <Text style={{ fontSize: 32, fontWeight: '800', color: theme.colors.primary, marginTop: 4 }}>
            {bmi.value}
          </Text>
          <Text style={{ color: theme.colors.text, fontWeight: '600' }}>{bmi.category}</Text>
        </Card>
      )}

      <Field label="Age" value={age} onChangeText={setAge} placeholder="30" keyboardType="number-pad" />
      <Field label="Sex (male/female/other)" value={sex} onChangeText={setSex} placeholder="female" />
      <Field label="Height (cm)" value={heightCm} onChangeText={setHeightCm} placeholder="170" keyboardType="decimal-pad" />
      <Field label="Weight (kg)" value={weightKg} onChangeText={setWeightKg} placeholder="65" keyboardType="decimal-pad" />
      <Field label="Activity (sedentary/light/moderate/active)" value={activity} onChangeText={setActivity} placeholder="moderate" />
      <Field label="Goal" value={goal} onChangeText={setGoal} placeholder="lose weight" autoCapitalize="sentences" />

      <Button title="Save Profile" onPress={onSave} loading={saving} />
      <View style={{ height: 12 }} />
      <Button title="Log out" variant="ghost" onPress={logout} />
    </ScrollView>
  );
}
