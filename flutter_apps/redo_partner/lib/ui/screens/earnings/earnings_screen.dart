import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../widgets/ui_components.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Partner Earnings & Wallet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Balance Card
            Card(
              color: AppColors.slateDark,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE WALLET BALANCE',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandYellow),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currency.format(48600.0),
                      style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Guaranteed advance payouts credited directly via UPI / IMPS.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkFaint),
                    ),
                    const SizedBox(height: 16),
                    RedoButton(
                      title: 'Withdraw to Bank Account',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Instant withdrawal request submitted!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recent Completed Trips Payout Ledger
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Trip Settlements', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _SettlementRow(
                      id: 'BK-89421',
                      trip: 'Mumbai ➔ Delhi NCR',
                      date: '28 Aug 2026',
                      amount: 22100.0,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _SettlementRow(
                      id: 'BK-77210',
                      trip: 'Jaipur ➔ Surat',
                      date: '24 Aug 2026',
                      amount: 18500.0,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _SettlementRow(
                      id: 'BK-61902',
                      trip: 'Pune ➔ Ahmedabad',
                      date: '19 Aug 2026',
                      amount: 16200.0,
                    ),
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
  final String id;
  final String trip;
  final String date;
  final double amount;

  const _SettlementRow({
    required this.id,
    required this.trip,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trip, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
              Text('$id • $date', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
            ],
          ),
          Text(
            '+ ${currency.format(amount)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
