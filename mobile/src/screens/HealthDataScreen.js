import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, ActivityIndicator, Linking, Pressable } from 'react-native';
import { Field } from '../components/Field';
import { Button, Card } from '../components/UI';
import { theme } from '../theme';
import { api } from '../api';

export default function HealthDataScreen() {
  const [keyword, setKeyword] = useState('');
  const [topics, setTopics] = useState([]);
  const [loading, setLoading] = useState(true);

  const [drugQ, setDrugQ] = useState('');
  const [drug, setDrug] = useState(null);
  const [drugLoading, setDrugLoading] = useState(false);

  async function loadTopics() {
    setLoading(true);
    try {
      const r = await api.topics({ keyword: keyword || undefined });
      setTopics(r.topics || []);
    } catch (e) {
      console.warn(e);
    } finally {
      setLoading(false);
    }
  }

  async function searchDrug() {
    if (!drugQ.trim()) return;
    setDrugLoading(true);
    try {
      const r = await api.drug(drugQ.trim());
      setDrug(r);
    } catch (e) {
      setDrug({ results: [], error: e.message });
    } finally {
      setDrugLoading(false);
    }
  }

  useEffect(() => { loadTopics(); }, []);

  return (
    <ScrollView style={{ flex: 1, backgroundColor: theme.colors.bg }} contentContainerStyle={{ padding: 20, paddingTop: 60 }}>
      <Text style={{ fontSize: 28, fontWeight: '800', color: theme.colors.text }}>Live Health Data</Text>
      <Text style={{ color: theme.colors.muted, marginBottom: 18 }}>
        From U.S. Health.gov & Open FDA
      </Text>

      <Text style={{ fontWeight: '700', fontSize: 16, marginBottom: 8, color: theme.colors.text }}>
        🔎 Health Topics
      </Text>
      <Field placeholder="e.g. nutrition, sleep, exercise" value={keyword} onChangeText={setKeyword} autoCapitalize="none" />
      <Button title="Search Topics" onPress={loadTopics} />

      <View style={{ marginTop: 16 }}>
        {loading ? (
          <ActivityIndicator color={theme.colors.primary} />
        ) : topics.length === 0 ? (
          <Text style={{ color: theme.colors.muted }}>No topics found.</Text>
        ) : (
          topics.slice(0, 12).map((t) => (
            <Pressable key={t.id} onPress={() => t.url && Linking.openURL(t.url)}>
              <Card style={{ marginBottom: 10 }}>
                <Text style={{ fontWeight: '700', color: theme.colors.text }}>{t.title}</Text>
                {t.categories ? (
                  <Text style={{ color: theme.colors.muted, fontSize: 12, marginTop: 4 }}>{t.categories}</Text>
                ) : null}
                <Text style={{ color: theme.colors.primary, fontSize: 12, marginTop: 6 }}>Tap to read →</Text>
              </Card>
            </Pressable>
          ))
        )}
      </View>

      <View style={{ height: 28 }} />

      <Text style={{ fontWeight: '700', fontSize: 16, marginBottom: 8, color: theme.colors.text }}>
        💊 Drug Lookup (Open FDA)
      </Text>
      <Field placeholder="e.g. ibuprofen, metformin" value={drugQ} onChangeText={setDrugQ} autoCapitalize="none" />
      <Button title="Search Drug" onPress={searchDrug} loading={drugLoading} />

      <View style={{ marginTop: 16 }}>
        {drug?.results?.length
          ? drug.results.map((r, i) => (
              <Card key={i} style={{ marginBottom: 10 }}>
                <Text style={{ fontWeight: '700', color: theme.colors.text }}>
                  {r.brand || r.generic}
                </Text>
                {r.generic && r.brand ? (
                  <Text style={{ color: theme.colors.muted, fontSize: 12 }}>generic: {r.generic}</Text>
                ) : null}
                {r.purpose ? (
                  <Text style={{ marginTop: 8, color: theme.colors.text }}>
                    <Text style={{ fontWeight: '700' }}>Purpose: </Text>{r.purpose}
                  </Text>
                ) : null}
                {r.indications ? (
                  <Text style={{ marginTop: 6, color: theme.colors.text }} numberOfLines={4}>
                    <Text style={{ fontWeight: '700' }}>Use: </Text>{r.indications}
                  </Text>
                ) : null}
                {r.warnings ? (
                  <Text style={{ marginTop: 6, color: theme.colors.danger }} numberOfLines={3}>
                    <Text style={{ fontWeight: '700' }}>⚠ Warnings: </Text>{r.warnings}
                  </Text>
                ) : null}
              </Card>
            ))
          : drug && <Text style={{ color: theme.colors.muted }}>No results.</Text>}
      </View>
    </ScrollView>
  );
}
