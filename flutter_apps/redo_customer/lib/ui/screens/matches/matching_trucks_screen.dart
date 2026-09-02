import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/booking_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../shipments/tracking_screen.dart';

class MatchingTrucksScreen extends StatelessWidget {
  const MatchingTrucksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<BookingViewModel>();
    final matches = bookingVM.matches;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Return Trucks', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('${bookingVM.origin} ➔ ${bookingVM.destination}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
          ],
        ),
      ),
      body: matches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.no_transfer, size: 48, color: AppColors.inkMuted),
                  const SizedBox(height: 12),
                  Text('No direct matching return trips found right now.', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final match = matches[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Match Score & Discount Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified, size: 14, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${match.matchScore.toInt()}% Route Match',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${match.backhaulDiscountPercent.toInt()}% Backhaul Discount',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Truck Specs & Reg
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.local_shipping_outlined, color: AppColors.slateDark, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    match.truckType,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                                  ),
                                  Text(
                                    'Reg: ${match.registrationNumber ?? "Verified Truck"} • Cap: ${match.availableCapacityTons} Tons',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 14),

                        // Pricing & Departure info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Est. spot market: ${currency.format(match.basePriceInr)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.inkMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currency.format(match.finalPriceInr),
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.slateDark,
                                  ),
                                ),
                                Text(
                                  'Ready to Depart: ${match.departureAt}',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 130,
                              child: RedoButton(
                                title: 'Book Now',
                                isLoading: bookingVM.isLoading,
                                onPressed: () async {
                                  final success = await bookingVM.confirmBooking(match);
                                  if (success && context.mounted) {
                                    final booking = bookingVM.lastBooking;
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TrackingScreen(booking: booking),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
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
