import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final sampleInvoices = [
      {
        'id': 'INV-2026-0891',
        'trip': 'Mumbai ➔ Delhi NCR',
        'date': '28 Aug 2026',
        'base': 22100.0,
        'gst': 3978.0,
        'total': 26078.0,
        'status': 'PAID',
      },
      {
        'id': 'INV-2026-0844',
        'trip': 'Jaipur ➔ Surat',
        'date': '25 Aug 2026',
        'base': 18500.0,
        'gst': 3330.0,
        'total': 21830.0,
        'status': 'PAID',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Tax Invoices & GST'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sampleInvoices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final inv = sampleInvoices[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(inv['id'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          inv['status'] as String,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(inv['trip'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('Billed on ${inv["date"]}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Base: ${currency.format(inv["base"])} + 18% GST', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
                      Text(currency.format(inv['total']), style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.slateDark)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
