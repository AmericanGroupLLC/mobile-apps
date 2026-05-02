import React, { useEffect, useState, useCallback } from 'react';
import { View, Text, ScrollView, RefreshControl, ActivityIndicator } from 'react-native';
import { Card } from '../components/UI';
import { theme } from '../theme';
import { useAuth } from '../auth';
import { api } from '../api';

function StatTile({ label, value, hint, color }) {
  return (
    <Card style={{ flex: 1, marginHorizontal: 4 }}>
      <Text style={{ color: theme.colors.muted, fontWeight: '600', fontSize: 12, textTransform: 'uppercase', letterSpacing: 1 }}>
        {label}
      </Text>
      <Text style={{ fontSize: 28, fontWeight: '800', color: color || theme.colors.text, marginTop: 4 }}>
        {value}
      </Text>
      {hint ? <Text style={{ color: theme.colors.muted, fontSize: 12, marginTop: 2 }}>{hint}</Text> : null}
    </Card>
  );
}

export default function HomeScreen() {
  const { user } = useAuth();
  const [data, setData] = useState(null);
  const [topics, setTopics] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    try {
      const [profileRes, topicsRes] = await Promise.all([
        api.getProfile(),
        api.topics({}),
      ]);
      setData(profileRes);
      setTopics((topicsRes.topics || []).slice(0, 4));
    } catch (e) {
      // Surface but don't crash
      console.warn(e);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: theme.colors.bg }}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  const bmi = data?.bmi;
  const weight = data?.profile?.weight_kg;
  const goal = data?.profile?.goal || 'Not set';

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: theme.colors.bg }}
      contentContainerStyle={{ padding: 16, paddingTop: 60 }}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load(); }} />}
    >
      <Text style={{ fontSize: 16, color: theme.colors.muted }}>Hello,</Text>
      <Text style={{ fontSize: 28, fontWeight: '800', color: theme.colors.text, marginBottom: 18 }}>
        {user?.name || 'Friend'} 👋
      </Text>

      <View style={{ flexDirection: 'row', marginHorizontal: -4, marginBottom: 12 }}>
        <StatTile label="BMI" value={bmi?.value ?? '—'} hint={bmi?.category} color={theme.colors.primary} />
        <StatTile label="Weight" value={weight ? `${weight}kg` : '—'} hint="from profile" />
      </View>
      <View style={{ flexDirection: 'row', marginHorizontal: -4, marginBottom: 24 }}>
        <StatTile label="Goal" value={goal} color={theme.colors.purple} />
      </View>

      <Text style={{ fontSize: 18, fontWeight: '700', color: theme.colors.text, marginBottom: 12 }}>
        Featured Health Topics
      </Text>
      {topics.length === 0 && (
        <Text style={{ color: theme.colors.muted }}>No topics found right now.</Text>
      )}
      {topics.map((t) => (
        <Card key={t.id} style={{ marginBottom: 12 }}>
          <Text style={{ fontSize: 16, fontWeight: '700', color: theme.colors.text }}>{t.title}</Text>
          {t.lastUpdated ? (
            <Text style={{ color: theme.colors.muted, fontSize: 12, marginTop: 4 }}>
              Updated {t.lastUpdated}
            </Text>
          ) : null}
        </Card>
      ))}
      <Text style={{ color: theme.colors.muted, fontSize: 12, marginTop: 16, textAlign: 'center' }}>
        Data: health.gov MyHealthfinder · Open FDA
      </Text>
    </ScrollView>
  );
}
