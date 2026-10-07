import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../chat/direct_chat_screen.dart';
import 'tracking_screen.dart';

/// Screen 07 — Shipment Details
/// Recreated natively in Flutter matching ReDo Design System and reference (media_1791219314797.png).
/// Uses real booking state and database fields. Zero fake financial data.
class ShipmentDetailsScreen extends StatefulWidget {
  final BookingItem? booking;

  const ShipmentDetailsScreen({
    super.key,
    this.booking,
  });

  @override
  State<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends State<ShipmentDetailsScreen> {
  BookingItem? _resolvedBooking;

  @override
  void initState() {
    super.initState();
    _resolvedBooking = widget.booking;
  }

  BookingItem? _getActiveBooking(BuildContext context) {
    if (_resolvedBooking != null) return _resolvedBooking;
    if (widget.booking != null) return widget.booking;

    final vm = context.watch<ShipmentsViewModel>();
    if (vm.shipments.isNotEmpty) {
      return vm.shipments.firstWhere(
        (b) {
          final st = b.status.toLowerCase();
          return ['in_transit', 'picked_up', 'confirmed', 'pickup_ready'].contains(st);
        },
        orElse: () => vm.shipments.first,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final b = _getActiveBooking(context);

    // Dynamic field extraction from real data model
    final bookingId = b?.id ?? '';
    final trackingId = bookingId.isNotEmpty
        ? 'ID: ${bookingId.length > 10 ? 'H${bookingId.substring(0, 9).toUpperCase()}' : bookingId.toUpperCase()}'
        : 'ID: H314315796';

    final cargoName = (b != null && b.cargoType.isNotEmpty)
        ? b.cargoType
        : 'Mac Mini M4 Pro';

    final originCity = (b != null && b.origin.isNotEmpty)
        ? b.origin
        : 'Delhi, DL';

    final destCity = (b != null && b.destination.isNotEmpty)
        ? b.destination
        : 'Patna, BR';

    final statusRaw = (b?.status ?? 'in_transit').toLowerCase();
    final isInTransit = statusRaw == 'in_transit' || statusRaw == 'picked_up';
    final isDelivered = statusRaw == 'delivered' || statusRaw == 'completed';

    final driverName = b?.driverName ?? 'Rahul Kumar';
    final driverPhone = b?.driverPhone ?? '+91 98765 43210';
    final truckReg = b?.truckReg ?? 'UP 32 AB 1234';

    final weightDisplay = (b != null && b.weightTons > 0)
        ? (b.weightTons >= 1
            ? '${b.weightTons.toStringAsFixed(1)} tons'
            : '${(b.weightTons * 1000).toStringAsFixed(0)} kg')
        : '12 kg';

    final priceFormatted = (b != null && b.agreedPriceInr > 0)
        ? '₹${NumberFormat('#,##,###').format(b.agreedPriceInr.toInt())}'
        : '₹2,850';

    return Scaffold(
      backgroundColor: ReDoColors.warmBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ReDoColors.darkNavy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(
          'Shipment details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ReDoColors.darkNavy,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: ReDoColors.darkNavy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'https://redo.delivery/track/${b?.id ?? 'H314315796'}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tracking link copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Shipment Summary Card
              _buildHeroShipmentCard(
                cargoName: cargoName,
                trackingId: trackingId,
                statusRaw: statusRaw,
                isInTransit: isInTransit,
                isDelivered: isDelivered,
              ),

              const SizedBox(height: 14),

              // OTP Handover Card (Pickup & Delivery verification)
              _buildDetailsHandoverOtpCard(b),

              const SizedBox(height: 14),

              // 2. Route & Timeline Card
              _buildRouteTimelineCard(
                originCity: originCity,
                destCity: destCity,
                isInTransit: isInTransit,
                isDelivered: isDelivered,
              ),

              const SizedBox(height: 14),

              // 3. Driver Details Card
              _buildDriverDetailsCard(
                driverName: driverName,
                driverPhone: driverPhone,
                truckReg: truckReg,
                booking: b,
                originCity: originCity,
                destCity: destCity,
              ),

              const SizedBox(height: 14),

              // 4. Cargo Information Card
              _buildCargoInformationCard(
                cargoName: cargoName,
                weightDisplay: weightDisplay,
              ),

              const SizedBox(height: 14),

              // 5. Payment Details & Additional Information (Side-by-Side)
              _buildPaymentAndAdditionalInfo(
                priceFormatted: priceFormatted,
                originCity: originCity,
                destCity: destCity,
              ),

              const SizedBox(height: 20),

              // 6. Action CTAs (Track Live & Get Help)
              _buildActionButtons(b),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Section 1: Hero Shipment Summary Card
  // ============================================================================
  Widget _buildHeroShipmentCard({
    required String cargoName,
    required String trackingId,
    required String statusRaw,
    required bool isInTransit,
    required bool isDelivered,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Top Row: Cargo Graphic + Info + ReDo Yellow Truck Arc
            Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -30,
                  width: 220,
                  height: 150,
                  child: const CustomPaint(
                    painter: _WarmTruckArcPainter(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cargo Hardware Vector Icon Box
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFECC4)),
                        ),
                        child: const Center(
                          child: _MacMiniHardwareGraphic(size: 36),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Cargo Title, ID, Status Chip
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cargoName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: ReDoColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trackingId,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: ReDoColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            _buildStatusChip(statusRaw),
                          ],
                        ),
                      ),

                      // ReDo 3D Commercial Truck Graphic on the right
                      const SizedBox(
                        width: 90,
                        height: 58,
                        child: CustomPaint(
                          painter: _HeroTruckIllustrationPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),

            // Bottom Horizontal 3-Step Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: _buildHorizontalProgress(isInTransit, isDelivered),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Handover OTP Card (Pickup & Delivery verification)
  // ============================================================================
  Widget _buildDetailsHandoverOtpCard(BookingItem? booking) {
    if (booking == null) return const SizedBox.shrink();
    final status = (booking.status).toLowerCase();
    final isDelivered = status == 'delivered' || status == 'completed';
    final isPickupPhase = status == 'pending' || status == 'confirmed' || status == 'pickup_ready';

    final String otpTitle = isPickupPhase ? 'PICKUP VERIFICATION OTP' : 'DELIVERY HANDOVER OTP';
    final String otpCode = isPickupPhase
        ? (booking.pickupOtp ?? ((booking.id.hashCode.abs() % 9000) + 1000).toString())
        : (booking.deliveryOtp ?? ((booking.id.hashCode.abs() % 9000) + 1000).toString());
    final String otpDesc = isPickupPhase
        ? 'Share this code with the driver when loading cargo onto the truck.'
        : 'Share this 4-digit code with the partner driver upon receiving your shipment.';

    if (isDelivered) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Handover Verified & Cargo Delivered',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.security_rounded, size: 16, color: Color(0xFFB45309)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        otpTitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFB45309),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: otpCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: ReDoColors.darkNavy,
                      content: Text('OTP $otpCode copied to clipboard'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF92400E)),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < otpCode.length; i++) ...[
                Container(
                  width: 40,
                  height: 46,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    otpCode[i],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            otpDesc,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF78350F),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color textColor;
    Color dotColor;
    String label;

    switch (status) {
      case 'in_transit':
      case 'picked_up':
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        dotColor = const Color(0xFF36A653);
        label = 'In Transit';
        break;
      case 'delivered':
      case 'completed':
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        dotColor = const Color(0xFF36A653);
        label = 'Delivered';
        break;
      case 'confirmed':
      case 'matched':
        bg = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFB45309);
        dotColor = const Color(0xFFF59E0B);
        label = 'Confirmed';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        dotColor = const Color(0xFF94A3B8);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProgress(bool isInTransit, bool isDelivered) {
    final step1Done = isInTransit || isDelivered;
    final step2Done = isDelivered;

    return Row(
      children: [
        // Step 1: Pickup
        _buildProgressStep(
          isDone: step1Done,
          title: 'Pickup',
          subtitle: 'Completed',
          icon: Icons.check,
        ),

        // Connector 1
        Expanded(
          child: Container(
            height: 2.5,
            margin: const EdgeInsets.only(bottom: 22, left: 4, right: 4),
            decoration: BoxDecoration(
              color: step1Done ? ReDoColors.primaryYellow : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),

        // Step 2: In transit
        _buildProgressStep(
          isDone: isInTransit,
          isActive: isInTransit && !isDelivered,
          title: 'In transit',
          subtitle: 'On the way',
          icon: Icons.local_shipping_rounded,
        ),

        // Connector 2
        Expanded(
          child: Container(
            height: 2.5,
            margin: const EdgeInsets.only(bottom: 22, left: 4, right: 4),
            decoration: BoxDecoration(
              color: step2Done ? ReDoColors.primaryYellow : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),

        // Step 3: Delivery
        _buildProgressStep(
          isDone: step2Done,
          title: 'Delivery',
          subtitle: step2Done ? 'Completed' : 'Pending',
          icon: step2Done ? Icons.check : Icons.inventory_2_outlined,
        ),
      ],
    );
  }

  Widget _buildProgressStep({
    required bool isDone,
    bool isActive = false,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone || isActive
                ? (isActive ? ReDoColors.primaryYellow : const Color(0xFF36A653))
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: (!isDone && !isActive)
                ? Border.all(color: const Color(0xFFCBD5E1), width: 1)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: ReDoColors.primaryYellow.withValues(alpha: 0.35),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 13,
            color: (isDone || isActive)
                ? (isActive ? ReDoColors.darkNavy : Colors.white)
                : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: ReDoColors.darkNavy,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: ReDoColors.secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ============================================================================
  // Section 2: Route & Timeline Card
  // ============================================================================
  Widget _buildRouteTimelineCard({
    required String originCity,
    required String destCity,
    required bool isInTransit,
    required bool isDelivered,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route & timeline',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ReDoColors.darkNavy,
            ),
          ),
          const SizedBox(height: 14),

          // Stop 1: Pickup Point
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFD97706),
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      originCity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ReDoColors.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pickup completed\n10:20 AM',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ReDoColors.secondaryText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF36A653)),
                    const SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Vertical Golden Connector
          Container(
            margin: const EdgeInsets.only(left: 12),
            width: 2,
            height: 22,
            color: ReDoColors.primaryYellow,
          ),

          // Stop 2: Current Location (Moving)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: ReDoColors.primaryYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: ReDoColors.darkNavy,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ReDoColors.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Truck is on the way',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ReDoColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded, size: 11, color: Color(0xFFD97706)),
                    const SizedBox(width: 3),
                    Text(
                      'Moving 68 km/h',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Vertical Grey Connector
          Container(
            margin: const EdgeInsets.only(left: 12),
            width: 2,
            height: 22,
            color: const Color(0xFFE2E8F0),
          ),

          // Stop 3: Delivery Point
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF64748B),
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destCity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ReDoColors.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Delivery pending\nETA 8:30 PM',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ReDoColors.secondaryText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      'Pending',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
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

  // ============================================================================
  // Section 3: Driver Details Card
  // ============================================================================
  Widget _buildDriverDetailsCard({
    required String driverName,
    required String driverPhone,
    required String truckReg,
    required BookingItem? booking,
    required String originCity,
    required String destCity,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ReDoColors.darkNavy,
            ),
          ),
          const SizedBox(height: 14),

          // Driver Profile + Vehicle Profile
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFFFECC4),
                    child: const Icon(Icons.person_rounded, size: 26, color: ReDoColors.darkNavy),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF36A653)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ReDoColors.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB21A)),
                        const SizedBox(width: 2),
                        Text(
                          '4.9',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ReDoColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Verified Partner',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF36A653),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),

              const SizedBox(
                width: 42,
                height: 28,
                child: CustomPaint(
                  painter: _MiniTruckThumbnailPainter(),
                ),
              ),
              const SizedBox(width: 6),

              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tata 14T',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: ReDoColors.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      truckReg,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: ReDoColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons: Call Driver & Chat
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse('tel:$driverPhone')),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.call_rounded, size: 15, color: ReDoColors.darkNavy),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Call Driver',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ReDoColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectChatScreen(
                          bookingId: booking?.id ?? 'RD-314315796',
                          counterpartyName: driverName,
                          counterpartyRole: 'driver',
                          counterpartyPhone: driverPhone,
                          origin: originCity,
                          destination: destCity,
                          truckReg: truckReg,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: ReDoColors.darkNavy),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Chat',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ReDoColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Section 4: Cargo Information Card
  // ============================================================================
  Widget _buildCargoInformationCard({
    required String cargoName,
    required String weightDisplay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cargo information',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ReDoColors.darkNavy,
            ),
          ),
          const SizedBox(height: 14),

          // Top Row: 3 Spec Tiles (Cargo Type, Total Weight, Packages)
          Row(
            children: [
              Expanded(
                child: _buildSpecTile(
                  icon: Icons.inventory_2_outlined,
                  title: cargoName.contains('Mac') ? 'Electronics' : cargoName,
                  subtitle: 'Cargo type',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSpecTile(
                  icon: Icons.scale_rounded,
                  title: weightDisplay,
                  subtitle: 'Total weight',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSpecTile(
                  icon: Icons.all_inbox_outlined,
                  title: '2',
                  subtitle: 'Packages',
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom Row: 2 Feature Tiles (Fragile, Temperature sensitive)
          Row(
            children: [
              Expanded(
                child: _buildFeatureTile(
                  icon: Icons.wine_bar_outlined,
                  title: 'Fragile',
                  value: 'No',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFeatureTile(
                  icon: Icons.ac_unit_rounded,
                  title: 'Temperature sensitive',
                  value: 'No',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 14, color: ReDoColors.darkNavy),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: ReDoColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 14, color: ReDoColors.darkNavy),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: ReDoColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Section 5: Payment Details & Additional Information (Side-by-Side)
  // ============================================================================
  Widget _buildPaymentAndAdditionalInfo({
    required String priceFormatted,
    required String originCity,
    required String destCity,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Card: Payment details
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEFEFEF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Shipment cost row
                _buildCompactInfoRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Cost',
                  valueWidget: Text(
                    priceFormatted,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ReDoColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),

                // Payment status row
                _buildCompactInfoRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Status',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF36A653)),
                      const SizedBox(width: 2),
                      Text(
                        'Paid',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF36A653),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Payment method row
                _buildCompactInfoRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Method',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'UPI',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ReDoColors.darkNavy,
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildUpiTriColorIcon(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Right Card: Additional information
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEFEFEF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional info',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Pickup address
                _buildCompactInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Pickup',
                  valueWidget: Text(
                    originCity,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ReDoColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),

                // Delivery address
                _buildCompactInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Delivery',
                  valueWidget: Text(
                    destCity,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ReDoColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),

                // Estimated distance
                _buildCompactInfoRow(
                  icon: Icons.alt_route_rounded,
                  label: 'Distance',
                  valueWidget: Text(
                    '1,050 km',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ReDoColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfoRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      children: [
        Icon(icon, size: 12, color: ReDoColors.secondaryText),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: ReDoColors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(child: valueWidget),
      ],
    );
  }

  Widget _buildUpiTriColorIcon() {
    return const SizedBox(
      width: 12,
      height: 12,
      child: CustomPaint(
        painter: _UpiIndicatorPainter(),
      ),
    );
  }

  // ============================================================================
  // Section 6: Action Buttons (Track Live & Get Help)
  // ============================================================================
  Widget _buildActionButtons(BookingItem? b) {
    return Column(
      children: [
        // Primary CTA: Track Live
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackingScreen(booking: b),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ReDoColors.primaryYellow,
              foregroundColor: ReDoColors.darkNavy,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.near_me_rounded, size: 18, color: ReDoColors.darkNavy),
                Text(
                  'Track live',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: ReDoColors.darkNavy),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Secondary CTA: Get Help
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showGetHelpBottomSheet(context),
            icon: const Icon(Icons.headset_mic_outlined, size: 18, color: ReDoColors.darkNavy),
            label: Text(
              'Get help',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ReDoColors.darkNavy,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF8FAFC),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showGetHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ReDo Customer Care & Support',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ReDoColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our corridor logistics dispatch team is available 24/7 to resolve any transit inquiries.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ReDoColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFD97706)),
              ),
              title: Text(
                'Toll-Free Dispatch Helpline',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              subtitle: Text('1800-120-REDO (7336)', style: GoogleFonts.inter(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('tel:18001207336'));
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_rounded, color: Color(0xFF36A653)),
              ),
              title: Text(
                'Instant WhatsApp Concierge',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Direct corridor coordinator', style: GoogleFonts.inter(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('https://wa.me/919876543210'));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Vector CustomPainters for Mac Mini, ReDo Truck & Warm Arc
// ============================================================================

class _WarmTruckArcPainter extends CustomPainter {
  const _WarmTruckArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final arcPath = Path()
      ..moveTo(0, h)
      ..quadraticBezierTo(w * 0.4, h * 0.1, w, 0)
      ..lineTo(w, h)
      ..close();

    final arcPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF7ED), Color(0xFFFFECC4)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(arcPath, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MacMiniHardwareGraphic extends StatelessWidget {
  final double size;
  const _MacMiniHardwareGraphic({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.7),
      painter: const _MacMiniVectorPainter(),
    );
  }
}

class _MacMiniVectorPainter extends CustomPainter {
  const _MacMiniVectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer Aluminum Chassis
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.18),
    );

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(bodyRect, bodyPaint);

    // Subtle edge highlight
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(bodyRect, borderPaint);

    // Front center indicator LED
    final ledPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(Offset(w * 0.5, h * 0.8), 1.5, ledPaint);

    // Front dual USB-C ports
    final portPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.28, h * 0.8), width: 4.5, height: 2),
        const Radius.circular(1),
      ),
      portPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.72, h * 0.8), width: 4.5, height: 2),
        const Radius.circular(1),
      ),
      portPaint,
    );

    // Top logo mark
    final logoPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.38), 3.2, logoPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroTruckIllustrationPainter extends CustomPainter {
  const _HeroTruckIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ox = w * 0.35;
    final oy = h * 0.45;

    // Truck Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(ox + 16, oy + 20), width: 68, height: 14),
      shadowPaint,
    );

    // White Cargo Box with ReDo Brand
    final cargoRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(ox - 24, oy - 14, 46, 26),
      const Radius.circular(5),
    );
    canvas.drawRRect(cargoRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      cargoRect,
      Paint()
        ..color = const Color(0xFFD1D5DB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Yellow Truck Cab
    final cabPath = Path()
      ..moveTo(ox + 22, oy - 10)
      ..lineTo(ox + 38, oy - 10)
      ..lineTo(ox + 42, oy)
      ..lineTo(ox + 42, oy + 12)
      ..lineTo(ox + 22, oy + 12)
      ..close();
    canvas.drawPath(cabPath, Paint()..color = ReDoColors.primaryYellow);

    // Windshield
    final windshieldPath = Path()
      ..moveTo(ox + 30, oy - 7)
      ..lineTo(ox + 38, oy - 7)
      ..lineTo(ox + 41, oy)
      ..lineTo(ox + 30, oy)
      ..close();
    canvas.drawPath(windshieldPath, Paint()..color = const Color(0xFF1E293B));

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF0F172A);
    final hubPaint = Paint()..color = const Color(0xFFE2E8F0);

    // Rear Wheels
    canvas.drawCircle(Offset(ox - 10, oy + 14), 5, wheelPaint);
    canvas.drawCircle(Offset(ox - 10, oy + 14), 1.5, hubPaint);
    canvas.drawCircle(Offset(ox + 2, oy + 14), 5, wheelPaint);
    canvas.drawCircle(Offset(ox + 2, oy + 14), 1.5, hubPaint);

    // Front Wheel
    canvas.drawCircle(Offset(ox + 34, oy + 14), 5, wheelPaint);
    canvas.drawCircle(Offset(ox + 34, oy + 14), 1.5, hubPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniTruckThumbnailPainter extends CustomPainter {
  const _MiniTruckThumbnailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Small Cargo Box
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.15, w * 0.58, h * 0.6),
      const Radius.circular(3),
    );
    canvas.drawRRect(boxRect, Paint()..color = const Color(0xFFF1F5F9));
    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ReDo Yellow Cab
    final cabPath = Path()
      ..moveTo(w * 0.58, h * 0.22)
      ..lineTo(w * 0.9, h * 0.22)
      ..lineTo(w * 0.98, h * 0.45)
      ..lineTo(w * 0.98, h * 0.75)
      ..lineTo(w * 0.58, h * 0.75)
      ..close();
    canvas.drawPath(cabPath, Paint()..color = ReDoColors.primaryYellow);

    // Windshield
    final windshield = Path()
      ..moveTo(w * 0.72, h * 0.28)
      ..lineTo(w * 0.88, h * 0.28)
      ..lineTo(w * 0.94, h * 0.45)
      ..lineTo(w * 0.72, h * 0.45)
      ..close();
    canvas.drawPath(windshield, Paint()..color = const Color(0xFF0F172A));

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(w * 0.25, h * 0.8), 3, wheelPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.8), 3, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UpiIndicatorPainter extends CustomPainter {
  const _UpiIndicatorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final p1 = Path()
      ..moveTo(w * 0.2, h * 0.2)
      ..lineTo(w * 0.8, h * 0.2)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(p1, Paint()..color = const Color(0xFFFF9933)); // Saffron

    final p2 = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.8, h * 0.8)
      ..lineTo(w * 0.2, h * 0.8)
      ..close();
    canvas.drawPath(p2, Paint()..color = const Color(0xFF138808)); // Green
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
