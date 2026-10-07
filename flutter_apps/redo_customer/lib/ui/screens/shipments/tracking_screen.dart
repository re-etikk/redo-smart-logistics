import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/driver_location_stream_service.dart';
import '../../../viewmodels/live_tracking_viewmodel.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../../widgets/tracking_map_view.dart';
import '../chat/direct_chat_screen.dart';
import 'shipment_details_screen.dart';

/// Screen 06 — Live Tracking
/// Flagship real-time tracking interface decoupled across:
/// 1. Map UI (`TrackingMapView`)
/// 2. Tracking state (`LiveTrackingViewModel`)
/// 3. Telemetry Stream (`IDriverLocationStreamService`)
///
/// Handles GPS unavailable, driver offline, stale telemetry, network drops, and completion.
class TrackingScreen extends StatefulWidget {
  final BookingItem? booking;
  final void Function(int index)? onTabChangeRequested;

  const TrackingScreen({
    super.key,
    this.booking,
    this.onTabChangeRequested,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final LiveTrackingViewModel _trackingVM;
  BookingItem? _selected;

  @override
  void initState() {
    super.initState();
    _trackingVM = LiveTrackingViewModel();

    _selected = widget.booking;
    if (_selected != null) {
      _trackingVM.init(_selected!);
    } else {
      Future.microtask(() async {
        if (!mounted) return;
        final shipmentsVM = context.read<ShipmentsViewModel>();
        await shipmentsVM.fetchShipments(silent: true);
        if (mounted && _selected == null) {
          final active = shipmentsVM.shipments.where((b) {
            final st = b.status.toLowerCase();
            return ['in_transit', 'picked_up', 'confirmed', 'pickup_ready'].contains(st);
          }).toList();
          if (active.isNotEmpty) {
            setState(() => _selected = active.first);
            _trackingVM.init(active.first);
          } else if (shipmentsVM.shipments.isNotEmpty) {
            setState(() => _selected = shipmentsVM.shipments.first);
            _trackingVM.init(shipmentsVM.shipments.first);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _trackingVM.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Driver number $cleanPhone copied to clipboard'),
              backgroundColor: ReDoColors.darkNavy,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver number $cleanPhone copied to clipboard'),
            backgroundColor: ReDoColors.darkNavy,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _trackingVM,
      builder: (context, _) {
        final b = _trackingVM.booking ?? _selected;
        final trackingId = b != null && b.id.isNotEmpty
            ? (b.id.toUpperCase().startsWith('RD-') ? b.id.toUpperCase() : 'RD-${b.id.toUpperCase()}')
            : 'RD-314315796';
        final cargoName = b != null && b.cargoType.isNotEmpty ? b.cargoType : 'Mac Mini M4 Pro';
        final cargoId = b != null && b.id.isNotEmpty
            ? (b.id.toUpperCase().startsWith('H') ? b.id.toUpperCase() : 'H${b.id.toUpperCase()}')
            : 'H314315796';
        final originCity = b != null && b.origin.isNotEmpty ? b.origin.split(',').first.trim() : 'Delhi';
        final destCity = b != null && b.destination.isNotEmpty ? b.destination.split(',').first.trim() : 'Patna';
        final etaText = _trackingVM.etaText;
        final distText = _trackingVM.remainingDistanceText;
        final driverName = b?.driverName ?? 'Rahul Kumar';
        final driverRating = '4.9';
        final driverPhone = b?.driverPhone ?? '+91 98765 43210';
        final vehicleModel = 'Tata 14T';
        final vehiclePlate = b?.truckReg ?? 'UP 32 AB 1234';

        return Scaffold(
          backgroundColor: ReDoColors.warmBackground,
          body: Stack(
            children: [
              // 1. Abstraction Layer: Interactive Map Component (Decoupled from tracking business logic)
              Positioned.fill(
                child: TrackingMapView(
                  pickupLocation: _trackingVM.pickupLocation,
                  dropLocation: _trackingVM.dropLocation,
                  driverLocation: _trackingVM.driverLocation,
                  routePoints: _trackingVM.routePoints,
                  originCity: originCity,
                  destinationCity: destCity,
                  isDriverOffline: _trackingVM.isDriverOffline,
                ),
              ),

              // 2. Floating Top Header Pill
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildFloatingTopBar(trackingId, _trackingVM),
                  ),
                ),
              ),

              // 3. Floating Resilience Alert Banner (GPS unavailable, offline, stale, or delivered)
              Positioned(
                top: 76,
                left: 16,
                right: 16,
                child: SafeArea(
                  child: _buildTrackingStatusAlert(_trackingVM),
                ),
              ),

              // 4. Bottom Draggable Details Card
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomCard(
                  booking: b,
                  cargoName: cargoName,
                  cargoId: cargoId,
                  etaText: etaText,
                  distText: distText,
                  driverName: driverName,
                  driverRating: driverRating,
                  driverPhone: driverPhone,
                  vehicleModel: vehicleModel,
                  vehiclePlate: vehiclePlate,
                  originCity: originCity,
                  destCity: destCity,
                  trackingVM: _trackingVM,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // Top Floating Bar (Back Button + "Live tracking" + Tracking ID + Status Chip)
  // ============================================================================
  Widget _buildFloatingTopBar(String trackingId, LiveTrackingViewModel vm) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: ReDoColors.darkNavy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Live tracking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  trackingId,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ReDoColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildStatusChip(vm),
        ],
      ),
    );
  }

  Widget _buildStatusChip(LiveTrackingViewModel vm) {
    Color bgColor = const Color(0xFFE8F5E9);
    Color dotColor = const Color(0xFF36A653);
    Color textColor = const Color(0xFF2E7D32);
    String label = 'In Transit';

    if (vm.isShipmentCompleted) {
      bgColor = const Color(0xFFE8F5E9);
      dotColor = const Color(0xFF10B981);
      textColor = const Color(0xFF047857);
      label = 'Delivered';
    } else if (vm.isDriverOffline) {
      bgColor = const Color(0xFFFEF2F2);
      dotColor = const Color(0xFFEF4444);
      textColor = const Color(0xFFB91C1C);
      label = 'Offline';
    } else if (vm.connectionStatus == DriverConnectionStatus.stale) {
      bgColor = const Color(0xFFFFFBEB);
      dotColor = const Color(0xFFF59E0B);
      textColor = const Color(0xFFB45309);
      label = 'Delayed';
    } else if (vm.shipmentStatus == 'picked_up') {
      bgColor = const Color(0xFFEFF6FF);
      dotColor = const Color(0xFF3B82F6);
      textColor = const Color(0xFF1D4ED8);
      label = 'Picked Up';
    } else if (vm.shipmentStatus == 'confirmed') {
      bgColor = const Color(0xFFFFFBEB);
      dotColor = const Color(0xFFF59E0B);
      textColor = const Color(0xFFB45309);
      label = 'Assigned';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Resilience Alert Banner
  // ============================================================================
  Widget _buildTrackingStatusAlert(LiveTrackingViewModel vm) {
    if (vm.isShipmentCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Shipment successfully delivered at destination!',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (vm.isDriverOffline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Driver is offline. Showing last known satellite position.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (vm.isGpsUnavailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'GPS telemetry signal unavailable. Re-establishing link...',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (vm.isStale) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: Color(0xFFF59E0B), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Telemetry delayed. Signal last seen >1m ago.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================================
  // Bottom Draggable Details Card
  // ============================================================================
  Widget _buildBottomCard({
    required BookingItem? booking,
    required String cargoName,
    required String cargoId,
    required String etaText,
    required String distText,
    required String driverName,
    required String driverRating,
    required String driverPhone,
    required String vehicleModel,
    required String vehiclePlate,
    required String originCity,
    required String destCity,
    required LiveTrackingViewModel trackingVM,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 1. Cargo Details + ETA + Distance Remaining Row
              _buildCargoSummaryRow(
                cargoName: cargoName,
                cargoId: cargoId,
                etaText: etaText,
                distText: distText,
                trackingVM: trackingVM,
              ),

              const SizedBox(height: 12),

              // OTP Handover Card for Pickup & Delivery
              _buildHandoverOtpCard(booking),

              const SizedBox(height: 16),

              // 2. Dynamic Route Progression Timeline
              _buildRouteTimeline(trackingVM),

              const SizedBox(height: 16),

              // 3. Driver & Vehicle Profile Card
              _buildDriverVehicleCard(
                driverName: driverName,
                driverRating: driverRating,
                vehicleModel: vehicleModel,
                vehiclePlate: vehiclePlate,
              ),

              const SizedBox(height: 14),

              // 4. Call Driver & Chat Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildSecondaryActionButton(
                      icon: Icons.phone_rounded,
                      label: 'Call Driver',
                      onTap: () => _makePhoneCall(driverPhone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat',
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
                              truckReg: vehiclePlate,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 5. Full Width "View shipment details >" CTA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipmentDetailsScreen(booking: booking),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'View shipment details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ReDoColors.darkNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: ReDoColors.darkNavy,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Handover OTP Card (Pickup & Delivery verification)
  // ============================================================================
  Widget _buildHandoverOtpCard(BookingItem? booking) {
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
        : 'Share this code with the partner driver upon receiving your shipment.';

    if (isDelivered) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
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
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
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
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF92400E)),
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
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < otpCode.length; i++) ...[
                Container(
                  width: 36,
                  height: 42,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    otpCode[i],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            otpDesc,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF78350F),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Cargo Summary Row
  // ============================================================================
  Widget _buildCargoSummaryRow({
    required String cargoName,
    required String cargoId,
    required String etaText,
    required String distText,
    required LiveTrackingViewModel trackingVM,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isNarrow = w < 370;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: isNarrow ? 48 : 54,
              height: isNarrow ? 48 : 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFECC4)),
              ),
              child: const Center(
                child: _MacMiniVectorIcon(size: 34),
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cargoName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isNarrow ? 13 : 15,
                      fontWeight: FontWeight.w800,
                      color: ReDoColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: $cargoId',
                    style: GoogleFonts.inter(
                      fontSize: isNarrow ? 10 : 11,
                      fontWeight: FontWeight.w500,
                      color: ReDoColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: trackingVM.isShipmentCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF36A653),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          trackingVM.lastUpdatedText,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: trackingVM.isDriverOffline
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF15803D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ETA',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ReDoColors.secondaryText,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    etaText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isNarrow ? 14 : 16,
                      fontWeight: FontWeight.w900,
                      color: ReDoColors.darkNavy,
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

            Flexible(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Distance remaining',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ReDoColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    distText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isNarrow ? 14 : 16,
                      fontWeight: FontWeight.w900,
                      color: ReDoColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // Dynamic Route Progression Timeline
  // ============================================================================
  Widget _buildRouteTimeline(LiveTrackingViewModel vm) {
    final status = vm.shipmentStatus;
    final isPickupDone = ['picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'completed']
        .contains(status);
    final isInTransit = ['in_transit', 'out_for_delivery'].contains(status);
    final isDelivered = ['delivered', 'completed'].contains(status);

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 8),
            // Step 1: Pickup
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isPickupDone ? const Color(0xFF36A653) : ReDoColors.primaryYellow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPickupDone ? Icons.check : Icons.inventory_2_rounded,
                size: 16,
                color: isPickupDone ? Colors.white : ReDoColors.darkNavy,
              ),
            ),

            // Step 1 -> 2 Connector Line
            Expanded(
              child: Container(
                height: 3.5,
                decoration: BoxDecoration(
                  color: isPickupDone ? ReDoColors.primaryYellow : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Step 2: In transit
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isInTransit
                    ? ReDoColors.primaryYellow
                    : isDelivered
                        ? const Color(0xFF36A653)
                        : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                boxShadow: isInTransit
                    ? [
                        BoxShadow(
                          color: ReDoColors.primaryYellow.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
                border: !isInTransit && !isDelivered
                    ? Border.all(color: const Color(0xFFD1D5DB))
                    : null,
              ),
              child: Icon(
                isDelivered ? Icons.check : Icons.local_shipping_rounded,
                size: 18,
                color: isInTransit || !isDelivered
                    ? ReDoColors.darkNavy
                    : Colors.white,
              ),
            ),

            // Step 2 -> 3 Connector Line
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (isInTransit)
                    FractionallySizedBox(
                      widthFactor: (vm.progressPct / 100.0).clamp(0.15, 0.95),
                      child: Container(
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: ReDoColors.primaryYellow,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  if (isDelivered)
                    Container(
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF36A653),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),

            // Step 3: Delivery
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isDelivered ? const Color(0xFF36A653) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: isDelivered ? null : Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Icon(
                isDelivered ? Icons.check : Icons.inventory_2_outlined,
                size: 14,
                color: isDelivered ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Pickup',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ReDoColors.darkNavy,
                    ),
                  ),
                  Text(
                    isPickupDone ? 'Completed' : 'Pending',
                    style: GoogleFonts.inter(fontSize: 10, color: ReDoColors.secondaryText),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'In transit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ReDoColors.darkNavy,
                    ),
                  ),
                  Text(
                    isInTransit ? 'On the way' : isDelivered ? 'Finished' : 'Queued',
                    style: GoogleFonts.inter(fontSize: 10, color: ReDoColors.secondaryText),
                  ),
                  if (isInTransit)
                    Text(
                      '${vm.speedKmh.round()} km/h',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Delivery',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ReDoColors.darkNavy,
                    ),
                  ),
                  Text(
                    isDelivered ? 'Delivered' : 'Pending',
                    style: GoogleFonts.inter(fontSize: 10, color: ReDoColors.secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // Driver & Vehicle Card
  // ============================================================================
  Widget _buildDriverVehicleCard({
    required String driverName,
    required String driverRating,
    required String vehicleModel,
    required String vehiclePlate,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFECC4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: ReDoColors.darkNavy,
                          size: 26,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFF36A653),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        driverName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ReDoColors.darkNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB21A)),
                          const SizedBox(width: 2),
                          Text(
                            driverRating,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ReDoColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Verified Partner',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF36A653),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 44,
            color: const Color(0xFFE5E7EB),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFECC4)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: ReDoColors.primaryYellow,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vehicleModel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ReDoColors.darkNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        vehiclePlate,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: ReDoColors.darkNavy),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ReDoColors.darkNavy,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF3F4F6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

// ============================================================================
// Vector Mac Mini M4 Pro Hardware Icon
// ============================================================================
class _MacMiniVectorIcon extends StatelessWidget {
  final double size;
  const _MacMiniVectorIcon({this.size = 38});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.7),
      painter: _MacMiniPainter(),
    );
  }
}

class _MacMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(8),
    );

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE5E7EB), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRRect(bodyRect, bodyPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(bodyRect, borderPaint);

    final ledPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(Offset(w * 0.5, h * 0.8), 1.5, ledPaint);

    final portPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.28, h * 0.8), width: 5, height: 2),
        const Radius.circular(1),
      ),
      portPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.72, h * 0.8), width: 5, height: 2),
        const Radius.circular(1),
      ),
      portPaint,
    );

    final logoPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.38), 3.5, logoPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
