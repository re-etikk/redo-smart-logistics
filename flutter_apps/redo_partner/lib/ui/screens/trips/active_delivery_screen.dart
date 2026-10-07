import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../widgets/redo_partner_components.dart';
import '../chat/direct_chat_screen.dart';
import 'accepted_trip_screen.dart';
import 'delivery_otp_screen.dart';

/// Screen 07 — Active Delivery
/// Faithfully recreates the in-transit delivery screen matching Reference 07.
/// Shows full interactive map, floating destination & ETA bar,
/// shipment/customer/earnings details, 3-stop progress tracker, and navigation actions.
class ActiveDeliveryScreen extends StatelessWidget {
  final ActiveTrip trip;

  const ActiveDeliveryScreen({super.key, required this.trip});

  void _callCustomer(BuildContext context) async {
    final phone = trip.shipperPhone ?? '+919876543210';
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone call to $phone')),
        );
      }
    }
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          bookingId: trip.bookingId,
          counterpartyName: trip.shipperName.isNotEmpty ? trip.shipperName : 'Ritik Kumar',
          counterpartyRole: 'Customer',
          counterpartyPhone: trip.shipperPhone ?? '+91 98765 43210',
          origin: trip.origin,
          destination: trip.destination,
        ),
      ),
    );
  }

  void _navigateToDelivery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryOtpScreen(trip: trip),
      ),
    );
  }

  void _openTripDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AcceptedTripScreen(trip: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final origin = trip.origin.isNotEmpty ? trip.origin : 'Delhi, DL';
    final destination = trip.destination.isNotEmpty ? trip.destination : 'Patna, BR';
    final customerName = trip.shipperName.isNotEmpty ? trip.shipperName : 'Ritik Kumar';
    final cargoName = trip.cargoType.isNotEmpty ? trip.cargoType : 'Mac Mini M4 Pro';
    final payout = trip.payoutInr > 0 ? trip.payoutInr : 4850.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Full-bleed Interactive Map
            Positioned.fill(
              child: MapPanel(
                originName: origin,
                destName: destination,
                height: double.infinity,
                showControls: true,
              ),
            ),

            // 2. Top Header with Back, Brand, and "In transit" Status Chip
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ReDoPartnerColors.lightGrey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Brand
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: ReDoPartnerColors.brandYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: ReDoPartnerColors.darkNavy,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ReDo',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: ReDoPartnerColors.darkNavy,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Partner',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ReDoPartnerColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: ReDoPartnerColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'In transit',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: ReDoPartnerColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.more_vert_rounded, color: ReDoPartnerColors.darkNavy),
                  ],
                ),
              ),
            ),

            // 3. Floating Destination & ETA Card
            Positioned(
              top: 64,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: ReDoPartnerColors.darkNavy,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${destination.split(',').first.trim()} delivery',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                          Text(
                            'ETA 8:30 PM',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: ReDoPartnerColors.border),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(Icons.alt_route_rounded,
                            size: 18, color: ReDoPartnerColors.darkNavy),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '540 km',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: ReDoPartnerColors.darkNavy,
                              ),
                            ),
                            Text(
                              'remaining',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: ReDoPartnerColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: ReDoPartnerColors.secondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Sliding Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: ReDoPartnerColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Shipment Row
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ReDoPartnerColors.border),
                          ),
                          child: const Icon(
                            Icons.devices_rounded,
                            size: 24,
                            color: ReDoPartnerColors.darkNavy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cargoName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: ReDoPartnerColors.darkNavy,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        size: 11, color: ReDoPartnerColors.secondary),
                                    const SizedBox(width: 3),
                                    Text('Electronics',
                                        style: GoogleFonts.inter(
                                            fontSize: 11, color: ReDoPartnerColors.secondary)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(trip.weightTons > 0 ? trip.weightTons * 1000 : 12).toInt()} kg • 2 packages',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: ReDoPartnerColors.secondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Customer & Earnings Row
                    Row(
                      children: [
                        // Customer
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFE2E8F0),
                                child: const Icon(Icons.person_rounded,
                                    size: 22, color: ReDoPartnerColors.darkNavy),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer',
                                      style: GoogleFonts.inter(
                                          fontSize: 10, color: ReDoPartnerColors.secondary),
                                    ),
                                    Text(
                                      customerName,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: ReDoPartnerColors.darkNavy,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded,
                                              size: 11, color: ReDoPartnerColors.success),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Verified customer',
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: ReDoPartnerColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: ReDoPartnerColors.border),
                        const SizedBox(width: 12),
                        // Earnings
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 18,
                                  color: Color(0xFFB78103),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Earnings',
                                      style: GoogleFonts.inter(
                                          fontSize: 10, color: ReDoPartnerColors.secondary),
                                    ),
                                    Text(
                                      currency.format(payout),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: ReDoPartnerColors.darkNavy,
                                      ),
                                    ),
                                    Text(
                                      'Estimated earnings',
                                      style: GoogleFonts.inter(
                                          fontSize: 9, color: ReDoPartnerColors.secondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3-Stop Milestone Progress Tracker
                    _buildMilestoneTracker(),
                    const SizedBox(height: 14),

                    // Call & Message Customer Row
                    Row(
                      children: [
                        Expanded(
                          child: PartnerSecondaryButton(
                            title: 'Call customer',
                            icon: Icons.phone_rounded,
                            onPressed: () => _callCustomer(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PartnerSecondaryButton(
                            title: 'Message customer',
                            icon: Icons.chat_bubble_outline_rounded,
                            onPressed: () => _openChat(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Primary CTA: Navigate to delivery
                    PartnerButton(
                      title: 'Navigate to delivery',
                      icon: Icons.navigation_rounded,
                      onPressed: () => _navigateToDelivery(context),
                    ),
                    const SizedBox(height: 8),

                    // Secondary CTA: Trip details
                    InkWell(
                      onTap: () => _openTripDetails(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F6F0),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: ReDoPartnerColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 16, color: ReDoPartnerColors.darkNavy),
                            const SizedBox(width: 8),
                            Text(
                              'Trip details',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: ReDoPartnerColors.darkNavy,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded,
                                size: 16, color: ReDoPartnerColors.darkNavy),
                          ],
                        ),
                      ),
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

  Widget _buildMilestoneTracker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              // 1. Pickup Check
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: ReDoPartnerColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
              // Connecting line 1 (Active)
              Expanded(
                child: Container(
                  height: 3,
                  color: ReDoPartnerColors.success,
                ),
              ),
              // 2. In Transit Ring
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9800), width: 4),
                ),
              ),
              // Connecting line 2 (Inactive)
              Expanded(
                child: Container(
                  height: 3,
                  color: ReDoPartnerColors.lightGrey,
                ),
              ),
              // 3. Delivery Ring
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: ReDoPartnerColors.secondary.withValues(alpha: 0.4), width: 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800)),
                    Text('10:45 AM', style: GoogleFonts.inter(fontSize: 10, color: ReDoPartnerColors.secondary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('In transit', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFE65100))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('540 km remaining', style: GoogleFonts.inter(fontSize: 10, color: ReDoPartnerColors.secondary)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Delivery', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Today, 8:30 PM', style: GoogleFonts.inter(fontSize: 10, color: ReDoPartnerColors.secondary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
