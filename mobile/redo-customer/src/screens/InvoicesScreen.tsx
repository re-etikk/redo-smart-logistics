import React, { useCallback, useState } from 'react';
import { FlatList, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { api } from '../lib/api';
import { C } from '../lib/theme';
import { Badge, Card, Empty, Stat } from '../components/ui';

export default function InvoicesScreen() {
  const [invoices, setInvoices] = useState<any[] | null>(null);
  useFocusEffect(useCallback(() => { api.get<any[]>('/invoices').then(setInvoices).catch(() => setInvoices([])); }, []));
  const list = invoices ?? [];
  const total = list.reduce((a, i) => a + Number(i.total_inr), 0);

  return (
    <View style={{ flex: 1, backgroundColor: C.canvas, padding: 14 }}>
      <Text style={{ fontSize: 20, fontWeight: '900', color: C.ink, marginBottom: 12 }}>Invoices &amp; Payments</Text>
      <View style={{ flexDirection: 'row', gap: 10, marginBottom: 12 }}>
        <Stat label="Invoices" value={list.length} />
        <Stat label="Total (incl. GST)" value={`₹${total.toLocaleString('en-IN')}`} />
      </View>
      {invoices !== null && list.length === 0 && (
        <Empty title="No invoices yet." hint="Invoices generate automatically when a shipment completes." />
      )}
      <FlatList data={list} keyExtractor={(i) => i.id} contentContainerStyle={{ gap: 10 }}
        renderItem={({ item: i }) => (
          <Card>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
              <Text style={{ fontWeight: '900', color: C.accent }}>{i.invoice_no}</Text>
              <Badge tone={i.status === 'paid' ? 'ok' : 'warn'} text={i.status === 'paid' ? 'Paid' : 'To be paid'} />
            </View>
            <Text style={{ fontSize: 12, color: C.inkSoft, marginTop: 4 }}>{i.route}</Text>
            <Text style={{ fontSize: 11, color: C.inkFaint, marginTop: 2 }}>
              Base ₹{Number(i.base_inr).toLocaleString('en-IN')} + GST ₹{Number(i.gst_inr).toLocaleString('en-IN')}
            </Text>
            <Text style={{ fontSize: 17, fontWeight: '900', color: C.ink, marginTop: 6 }}>
              ₹{Number(i.total_inr).toLocaleString('en-IN')}
            </Text>
          </Card>
        )} />
    </View>
  );
}
