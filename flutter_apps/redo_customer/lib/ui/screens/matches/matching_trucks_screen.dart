import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/unit_formatter.dart';
import '../../../viewmodels/booking_viewmodel.dart';
import '../../../viewmodels/theme_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../chat/direct_chat_screen.dart';
import '../shipments/tracking_screen.dart';

class MatchingTrucksScreen extends StatelessWidget {
  const MatchingTrucksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<BookingViewModel>();
    final isMetric = context.watch<ThemeViewModel>().isMetric;
    final matches = bookingVM.matches;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Return Trucks',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              '${bookingVM.origin} ➔ ${bookingVM.destination}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
      body: matches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.no_transfer,
                    size: 48,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No suitable return capacity found yet.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try another route or pickup window. REDO will only show verified backend matches.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final match = matches[index];
                final capacityText = UnitFormatter.formatWeightTons(
                  match.availableCapacityTons,
                  isMetric: isMetric,
                );

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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${match.matchScore.toInt()}% Route Match',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${match.backhaulDiscountPercent.toInt()}% Backhaul Discount',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFB45309),
                                ),
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
                              decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_shipping_outlined,
                                color: AppColors.slateDark,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    match.truckType,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    'Reg: ${match.registrationNumber ?? "Verified Truck"} • Cap: $capacityText',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Driver Rating & Eco-friendly Backhaul Chip
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 13,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${match.driverRating.toStringAsFixed(1)} • ${(match.onTimeRate * 100).toInt()}% On-Time',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slateDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.eco,
                                    size: 13,
                                    color: Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Zero Empty Haul • Low CO2',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 14),

                        // Pricing, Direct Chat & Book button
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
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DirectChatScreen(
                                          bookingId: 'match_${match.truckId}',
                                          counterpartyName:
                                              'Carrier (${match.registrationNumber ?? "Verified"})',
                                          counterpartyRole: 'Driver / Transporter',
                                          counterpartyPhone: '+91 98765 43210',
                                          origin: bookingVM.origin,
                                          destination: bookingVM.destination,
                                          truckReg: match.registrationNumber,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      color: AppColors.canvas,
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 20,
                                      color: AppColors.slateDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 110,
                                  child: RedoButton(
                                    title: 'Book Now',
                                    isLoading: bookingVM.isLoading,
                                    onPressed: () async {
                                      final success = await bookingVM
                                          .confirmBooking(match);
                                      if (success && context.mounted) {
                                        final booking = bookingVM.lastBooking;
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TrackingScreen(booking: booking),
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
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
