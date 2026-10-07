import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../widgets/redo_partner_components.dart';
import '../chat/direct_chat_screen.dart';
import 'navigation_screen.dart';

/// Screen 04 — Accepted Trip / Trip Details
/// Faithfully recreates the accepted-trip UI matching Reference 04.
/// Displays assigned trip, route, shipment, customer, and navigation CTA.
class AcceptedTripScreen extends StatelessWidget {
  final ActiveTrip trip;

  const AcceptedTripScreen({super.key, required this.trip});

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

  void _startNavigation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(trip: trip),
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

    return Scaffold(
      backgroundColor: ReDoPartnerColors.warmBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: ReDoPartnerColors.border)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
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
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          'Active trip',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: ReDoPartnerColors.darkNavy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
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
                                'Accepted',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: ReDoPartnerColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. Top Map Panel
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 220,
                  child: MapPanel(
                    originName: origin,
                    destName: destination,
                    height: 220,
                    showControls: false,
                  ),
                ),
              ),
              // Floating ETA badge
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_rounded,
                          size: 16, color: ReDoPartnerColors.darkNavy),
                      const SizedBox(width: 6),
                      Text(
                        '18 min • 10 km',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Map buttons
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.layers_outlined, size: 18, color: ReDoPartnerColors.darkNavy),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.my_location_rounded, size: 18, color: ReDoPartnerColors.darkNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Trip Route & Estimated Earnings Card
          PartnerCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip route',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ReDoPartnerColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              origin.split(',').first.trim(),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: ReDoPartnerColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: ReDoPartnerColors.secondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              destination.split(',').first.trim(),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: ReDoPartnerColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alt_route_rounded,
                                  size: 12, color: Color(0xFFFF9800)),
                              const SizedBox(width: 4),
                              Text(
                                '1,000 km',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ReDoPartnerColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Long haul',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 16,
                              color: ReDoPartnerColors.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.format(trip.payoutInr > 0 ? trip.payoutInr : 4850),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated earnings',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Shipment Card
          PartnerCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Shipment Graphic
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ReDoPartnerColors.border),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.devices_rounded,
                      size: 32,
                      color: ReDoPartnerColors.darkNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cargoName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 13, color: ReDoPartnerColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'Electronics',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: ReDoPartnerColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.lock_outline_rounded,
                                size: 13, color: ReDoPartnerColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              '${(trip.weightTons > 0 ? trip.weightTons * 1000 : 12).toInt()} kg',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: ReDoPartnerColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '2 packages',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: ReDoPartnerColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wine_bar_rounded,
                          size: 14, color: Color(0xFFD32F2F)),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fragile',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFD32F2F),
                            ),
                          ),
                          Text(
                            'Handle with care',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: const Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Pickup & Delivery Locations Card
          PartnerCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pickup row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFE65100),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup location',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                          Text(
                            origin,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                          Text(
                            '10 km away • ETA 18 min',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ReDoPartnerColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation_rounded,
                              size: 12, color: ReDoPartnerColors.darkNavy),
                          const SizedBox(width: 4),
                          Text(
                            'View on map',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Connector
                Padding(
                  padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB21A),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Delivery row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ReDoPartnerColors.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: ReDoPartnerColors.darkNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery location',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                          Text(
                            destination,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                          Text(
                            '1,000 km • Est. today, 8:30 PM',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ReDoPartnerColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation_rounded,
                              size: 12, color: ReDoPartnerColors.darkNavy),
                          const SizedBox(width: 4),
                          Text(
                            'View on map',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. Customer Card
          PartnerCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.person_rounded, size: 28, color: ReDoPartnerColors.darkNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: ReDoPartnerColors.secondary,
                        ),
                      ),
                      Text(
                        customerName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 13, color: ReDoPartnerColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Verified customer',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ReDoPartnerColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _callCustomer(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ReDoPartnerColors.lightGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_rounded,
                            size: 18, color: ReDoPartnerColors.darkNavy),
                        Text(
                          'Call',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: ReDoPartnerColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _openChat(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ReDoPartnerColors.lightGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 18, color: ReDoPartnerColors.darkNavy),
                        Text(
                          'Message',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: ReDoPartnerColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. Action Buttons
          PartnerButton(
            title: 'Navigate to pickup',
            icon: Icons.navigation_rounded,
            onPressed: () => _startNavigation(context),
          ),
          const SizedBox(height: 10),
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
        ],
      ),
    );
  }
}
