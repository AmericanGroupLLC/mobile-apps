/**
 * Finoapp — personal finance tracker.
 *
 * MVP placeholder UI: shows a current balance and a list of transactions
 * from in-memory mock data. The "Add" button is wired up to a stub.
 * Backend, persistence, and real auth are out of scope for v0.
 *
 * @format
 */

import React, {useMemo, useState} from 'react';
import {
  Alert,
  FlatList,
  Pressable,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
} from 'react-native';
import {
  SafeAreaProvider,
  SafeAreaView,
} from 'react-native-safe-area-context';

type Transaction = {
  id: string;
  description: string;
  amount: number; // positive = income, negative = expense
  category: string;
  date: string; // ISO 8601
};

const MOCK_TRANSACTIONS: Transaction[] = [
  {id: 't1', description: 'Paycheck',     amount:  3200.00, category: 'Income',    date: '2026-05-01'},
  {id: 't2', description: 'Rent',         amount: -1450.00, category: 'Housing',   date: '2026-05-01'},
  {id: 't3', description: 'Groceries',    amount:   -84.32, category: 'Food',      date: '2026-05-03'},
  {id: 't4', description: 'Coffee',       amount:    -5.75, category: 'Food',      date: '2026-05-04'},
  {id: 't5', description: 'Gas',          amount:   -42.10, category: 'Transport', date: '2026-05-06'},
  {id: 't6', description: 'Side gig',     amount:   180.00, category: 'Income',    date: '2026-05-07'},
];

function formatCurrency(value: number): string {
  const sign = value < 0 ? '-' : '';
  const abs = Math.abs(value).toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  return `${sign}$${abs}`;
}

function App(): React.JSX.Element {
  const isDark = useColorScheme() === 'dark';
  const theme = isDark ? darkTheme : lightTheme;
  const [transactions] = useState<Transaction[]>(MOCK_TRANSACTIONS);

  const balance = useMemo(
    () => transactions.reduce((sum, t) => sum + t.amount, 0),
    [transactions],
  );

  const onAddPress = () => {
    Alert.alert(
      'Add transaction',
      'Transaction entry is not implemented yet.',
      [{text: 'OK'}],
    );
  };

  return (
    <SafeAreaProvider>
      <StatusBar barStyle={isDark ? 'light-content' : 'dark-content'} />
      <SafeAreaView style={[styles.root, {backgroundColor: theme.bg}]}>
        <View style={styles.header}>
          <Text style={[styles.appName, {color: theme.fg}]}>Finoapp</Text>
          <Text style={[styles.tagline, {color: theme.muted}]}>
            personal finance tracker
          </Text>
        </View>

        <View style={[styles.balanceCard, {backgroundColor: theme.card}]}>
          <Text style={[styles.balanceLabel, {color: theme.muted}]}>
            Current balance
          </Text>
          <Text
            style={[
              styles.balanceValue,
              {color: balance < 0 ? theme.expense : theme.income},
            ]}>
            {formatCurrency(balance)}
          </Text>
        </View>

        <Text style={[styles.sectionHeader, {color: theme.muted}]}>
          Recent transactions
        </Text>
        <FlatList
          data={transactions}
          keyExtractor={t => t.id}
          contentContainerStyle={styles.list}
          renderItem={({item}) => (
            <View style={[styles.txRow, {borderBottomColor: theme.divider}]}>
              <View style={styles.txLeft}>
                <Text style={[styles.txDescription, {color: theme.fg}]}>
                  {item.description}
                </Text>
                <Text style={[styles.txMeta, {color: theme.muted}]}>
                  {item.category} · {item.date}
                </Text>
              </View>
              <Text
                style={[
                  styles.txAmount,
                  {color: item.amount < 0 ? theme.expense : theme.income},
                ]}>
                {formatCurrency(item.amount)}
              </Text>
            </View>
          )}
        />

        <Pressable
          onPress={onAddPress}
          style={({pressed}) => [
            styles.addButton,
            {backgroundColor: theme.accent, opacity: pressed ? 0.85 : 1},
          ]}>
          <Text style={styles.addButtonLabel}>+ Add transaction</Text>
        </Pressable>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const lightTheme = {
  bg:      '#F5F6FA',
  card:    '#FFFFFF',
  fg:      '#101319',
  muted:   '#5B6273',
  divider: '#E4E6EE',
  accent:  '#1F6FEB',
  income:  '#1F8B4C',
  expense: '#C1361A',
};

const darkTheme = {
  bg:      '#0E1117',
  card:    '#181B23',
  fg:      '#F0F2F8',
  muted:   '#8B93A7',
  divider: '#262A36',
  accent:  '#3F86F5',
  income:  '#4DAA72',
  expense: '#F0795E',
};

const styles = StyleSheet.create({
  root:           {flex: 1, paddingHorizontal: 20},
  header:         {paddingTop: 12, paddingBottom: 16},
  appName:        {fontSize: 28, fontWeight: '700'},
  tagline:        {fontSize: 13, marginTop: 2},
  balanceCard:    {borderRadius: 14, padding: 18, marginBottom: 24},
  balanceLabel:   {fontSize: 13, marginBottom: 4, textTransform: 'uppercase', letterSpacing: 0.5},
  balanceValue:   {fontSize: 36, fontWeight: '700'},
  sectionHeader:  {fontSize: 13, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 8},
  list:           {paddingBottom: 80},
  txRow:          {flexDirection: 'row', alignItems: 'center', paddingVertical: 12, borderBottomWidth: StyleSheet.hairlineWidth},
  txLeft:         {flex: 1, marginRight: 12},
  txDescription:  {fontSize: 16, fontWeight: '500'},
  txMeta:         {fontSize: 12, marginTop: 2},
  txAmount:       {fontSize: 16, fontWeight: '600'},
  addButton:      {position: 'absolute', left: 20, right: 20, bottom: 20, height: 52, borderRadius: 26, alignItems: 'center', justifyContent: 'center'},
  addButtonLabel: {color: '#FFFFFF', fontSize: 16, fontWeight: '600'},
});

export default App;
