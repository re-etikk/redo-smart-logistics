import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/ui_components.dart';

/// REAL earnings — computed by the backend from completed bookings
/// (settles when the shipper marks a trip completed). No hardcoded ledger.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await SupabaseService.getEarnings();
      if (mounted) setState(() { _data = d; _error = null; });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final totals = (_data?['totals'] as Map?) ?? {};
    final txns = (_data?['transactions'] as List?) ?? [];
    final completed = (totals['completed_inr'] as num?)?.toDouble() ?? 0;
    final pending = (totals['pending_inr'] as num?)?.toDouble() ?? 0;
    final trips = (totals['completed_trips'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Partner Earnings & Wallet')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.slateDark,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL EARNED (SETTLED)',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandYellow)),
                    const SizedBox(height: 6),
                    Text(currency.format(completed),
                        style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                        'Pending (trips awaiting completion): ${currency.format(pending)}  •  $trips trips settled',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.inkFaint)),
                    const SizedBox(height: 16),
                    RedoButton(
                      title: 'Withdraw to Bank (Demo)',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Demo: payout gateway (Razorpay/Cashfree) is a planned integration.')));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trip Settlements',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(_error!,
                          style: GoogleFonts.inter(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600)),
                    if (_error == null && txns.isEmpty)
                      Text(
                          'No settlements yet - complete trips to see payouts here.',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.inkMuted)),
                    for (var i = 0; i < txns.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      _SettlementRow(txn: Map<String, dynamic>.from(txns[i])),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _SettlementRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final settled = txn['settled'] == true;
    String date = '';
    final d = DateTime.tryParse('${txn['date'] ?? ''}')?.toLocal();
    if (d != null) date = DateFormat('d MMM yyyy').format(d);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${txn['route'] ?? 'Trip'}',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                Text(
                    '$date • ${settled ? 'Paid' : 'Pending shipper completion'}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color:
                            settled ? AppColors.inkMuted : AppColors.warning)),
              ],
            ),
          ),
          Text(
            '+ ${currency.format((txn['amount_inr'] as num?)?.toDouble() ?? 0)}',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: settled ? AppColors.success : AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
