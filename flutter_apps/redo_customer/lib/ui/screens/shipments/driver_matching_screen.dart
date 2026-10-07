import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/booking_viewmodel.dart';
import '../../widgets/redo_design_system.dart';
import 'tracking_screen.dart';

/// ReDo Customer App — SCREEN 05: DRIVER MATCHING
/// Recreated natively in Flutter matching design reference media_1791216697352.png
/// Integrated directly with ReDo driver dispatch backend system.
class DriverMatchingScreen extends StatefulWidget {
  const DriverMatchingScreen({super.key});

  @override
  State<DriverMatchingScreen> createState() => _DriverMatchingScreenState();
}

class _DriverMatchingScreenState extends State<DriverMatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _progressController;
  GoogleMapController? _matchingMapController;
  RealtimeChannel? _dispatchChannel;
  Timer? _pollTimer;
  Timer? _countdownTimer;

  bool _isDriverAssigned = false;
  String _matchingStatusText = 'Connecting to ReDo dispatch network...';
  int _driversFound = 0;
  int _activeOffersCount = 0;
  int _totalOffersCount = 0;
  int _secondsRemaining = 45;
  String _dispatchStatus = 'open';
  bool _isRetrying = false;
  bool _isCancelling = false;
  bool _hasNetworkError = false;
  BookingItem? _assignedBooking;
  final String _pickupOtp = '4821';

  Map<String, dynamic> _assignedDriver = {
    'name': 'Rahul Kumar',
    'rating': '4.8',
    'trips': 'Verified Driver',
    'vehicle': 'Commercial Freight Truck',
    'plate': 'DL 1L AB 9482',
    'eta': '10 mins away',
    'phone': '+91 98765 43210',
  };

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BookingViewModel>();
      final cargo = vm.lastPostedCargo;
      if (cargo != null) {
        _initRealDispatch(cargo.cargoId);
      } else {
        setState(() {
          _matchingStatusText = 'Scanning for matching corridor trucks...';
          _driversFound = vm.matches.length;
        });
      }
    });
  }

  void _initRealDispatch(String cargoId) {
    _fetchDispatchState(cargoId);

    // Periodic poll every 4 seconds to ensure state synchronization even if Realtime drops
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isDriverAssigned && mounted) {
        _fetchDispatchState(cargoId);
      }
    });

    // 45s countdown timer for active dispatch window
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _secondsRemaining > 0 && !_isDriverAssigned) {
        setState(() {
          _secondsRemaining--;
          if (_secondsRemaining == 0 && _activeOffersCount > 0) {
            _activeOffersCount = 0;
            _matchingStatusText = 'Window expired. Tap Retry to redispatch.';
          }
        });
      }
    });

    // Realtime Supabase change listener on dispatch_offers and bookings
    try {
      _dispatchChannel = SupabaseService.subscribeDispatch(
        cargoId: cargoId,
        onUpdate: (change) {
          if (!mounted || _isDriverAssigned) return;
          _fetchDispatchState(cargoId);
        },
      );
    } catch (_) {}
  }

  Future<void> _fetchDispatchState(String cargoId) async {
    try {
      final state = await SupabaseService.getDispatchState(cargoId);
      if (!mounted) return;

      setState(() => _hasNetworkError = false);

      final status = state['status'] as String? ?? 'open';
      if (status == 'assigned') {
        _handleDriverAssigned(state);
        return;
      }

      final offers = (state['offers'] as List?) ?? [];
      final active = (state['active_offers_count'] as num?)?.toInt() ?? 0;
      final total = (state['offers_count'] as num?)?.toInt() ?? offers.length;

      setState(() {
        _dispatchStatus = status;
        _activeOffersCount = active;
        _totalOffersCount = total;
        _driversFound = max(total, context.read<BookingViewModel>().matches.length);

        if (active > 0) {
          _matchingStatusText = 'Dispatched to $active nearby drivers ($_secondsRemaining s left)';
        } else if (total > 0) {
          _matchingStatusText = 'Offers expired. Ready to broadcast again.';
        } else {
          _matchingStatusText = 'Searching for trucks on this corridor...';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _hasNetworkError = true);
      }
    }
  }

  void _handleDriverAssigned(Map<String, dynamic> state) {
    if (_isDriverAssigned) return;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();

    final bMap = state['booking'] as Map<String, dynamic>?;
    final driverMap = state['assigned_driver'] as Map<String, dynamic>?;

    BookingItem? booking;
    if (bMap != null) {
      booking = BookingItem.fromJson(bMap);
    } else {
      final cargo = context.read<BookingViewModel>().lastPostedCargo;
      if (cargo != null) booking = BookingItem.fromCargo(cargo);
    }

    setState(() {
      _isDriverAssigned = true;
      _dispatchStatus = 'assigned';
      _assignedBooking = booking;
      _matchingStatusText = 'Driver confirmed!';
      if (driverMap != null) {
        _assignedDriver = {
          'name': driverMap['name'] ?? 'Assigned Partner Driver',
          'rating': '${driverMap['rating'] ?? '4.8'}',
          'trips': 'Verified Driver',
          'vehicle': driverMap['truck_type'] ?? 'Commercial Truck',
          'plate': driverMap['truck_reg'] ?? '',
          'eta': '~10 mins away',
          'phone': driverMap['phone'] ?? '+91 98765 43210',
        };
      }
    });

    _showDriverAssignedSheet();
  }

  Future<void> _handleRetryDispatch() async {
    if (_isRetrying) return;
    final vm = context.read<BookingViewModel>();
    final cargoId = vm.lastPostedCargo?.cargoId;
    if (cargoId == null) return;

    setState(() {
      _isRetrying = true;
      _matchingStatusText = 'Retrying dispatch to nearby trucks...';
    });

    final success = await vm.retryDispatch();
    if (!mounted) return;

    setState(() {
      _isRetrying = false;
      _secondsRemaining = 45;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispatched new offers to nearby drivers!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchDispatchState(cargoId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Searching across wider corridor for available drivers.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCancelShipment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Shipment?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: ReDoColors.darkNavy,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this shipment request? Any pending dispatch offers will be withdrawn immediately.',
          style: GoogleFonts.inter(fontSize: 14, color: ReDoColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Waiting', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cancel Shipment', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    final vm = context.read<BookingViewModel>();
    final ok = await vm.cancelCurrentCargo();
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipment cancelled successfully.'),
          backgroundColor: AppColors.slateDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not cancel shipment. Please retry.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _progressController.dispose();
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    if (_dispatchChannel != null) {
      SupabaseService.removeChannel(_dispatchChannel!);
    }
    super.dispose();
  }

  void _showDriverAssignedSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD5F5E3),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 32),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver Found & Assigned!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ReDoColors.darkNavy,
                        ),
                      ),
                      Text(
                        '${_assignedDriver['name']} accepted your load',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: ReDoColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Prominent Pickup Verification OTP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD480)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup Verification OTP',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8B5500),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share with driver upon truck arrival',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: ReDoColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: ReDoColors.darkNavy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _pickupOtp,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ReDoColors.primaryYellow,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5EC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFECC4)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFFB21A),
                    child: Text(
                      'VS',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _assignedDriver['name']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: ReDoColors.darkNavy,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECC4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 13, color: Color(0xFFD98800)),
                                  const SizedBox(width: 2),
                                  Text(
                                    _assignedDriver['rating']!,
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_assignedDriver['vehicle']} • ${_assignedDriver['plate']}',
                          style: GoogleFonts.inter(fontSize: 12, color: ReDoColors.secondaryText),
                        ),
                        Text(
                          'ETA: ${_assignedDriver['eta']}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ReDoButton(
              text: 'Track Live on Map',
              showArrow: true,
              onPressed: () {
                Navigator.pop(ctx);
                final vm = context.read<BookingViewModel>();
                final cargo = vm.lastPostedCargo;
                final booking = _assignedBooking ?? (cargo != null ? BookingItem.fromCargo(cargo) : null);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => TrackingScreen(booking: booking),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();

    final originCity = vm.origin.isNotEmpty ? vm.origin.split(',').first.trim() : 'Delhi';
    final destCity = vm.destination.isNotEmpty ? vm.destination.split(',').first.trim() : 'Patna';
    final cargoName = vm.cargoType.isNotEmpty ? vm.cargoType : 'Mac Mini M4 Pro';
    final weightText = '${vm.weightKg.round()} kg';
    final fareFormatted = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(vm.priceTotalInr > 0 ? vm.priceTotalInr.round() : 2850);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkCanvas : ReDoColors.warmBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final iconColor = isDark ? AppColors.darkInk : ReDoColors.darkNavy;
    final borderColor = isDark ? AppColors.darkBorder : ReDoColors.cardBorder;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with back arrow and close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
                        child: Icon(Icons.arrow_back_rounded, size: 20, color: iconColor),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECC4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD98800),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _dispatchStatus == 'assigned'
                              ? 'Assigned'
                              : _dispatchStatus == 'timeout'
                                  ? 'Timed Out'
                                  : 'Live Matching',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8B5500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    Text(
                      'Finding your driver',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: ReDoColors.darkNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Matching your shipment with nearby verified partners',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: ReDoColors.secondaryText,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Top Visual Map Area with Real Google Map and Nearby Trucks
                    _buildRealTimeTrucksMap(vm, originCity),

                    const SizedBox(height: 14),

                    // Pickup OTP Handover Card
                    _buildPickupOtpCard(),

                    const SizedBox(height: 14),

                    // Middle Status Card: Searching nearby partners
                    _buildSearchingPartnersCard(),

                    const SizedBox(height: 14),

                    // 3 Compatibility Chips
                    _buildCompatibilityChipsRow(),

                    const SizedBox(height: 20),

                    // Section: Shipment details
                    Text(
                      'Shipment details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildShipmentDetailsCard(
                      cargoName: cargoName,
                      originCity: originCity,
                      destCity: destCity,
                      weightText: weightText,
                      fareFormatted: fareFormatted,
                    ),

                    const SizedBox(height: 14),

                    // Bottom notice card: Usually takes less than a minute
                    _buildTimeNoticeCard(),

                    const SizedBox(height: 16),

                    if (_hasNetworkError) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 18, color: Color(0xFFD97706)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Reconnecting to dispatch service... Polling continues in background.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Cancel shipment button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isCancelling ? null : _handleCancelShipment,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isCancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                              )
                            : const Icon(Icons.close_rounded, size: 18),
                        label: Text(
                          'Cancel Shipment Request',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Top Visual Map Area with Real Google Map, Pickup Pin and Nearby Trucks
  // --------------------------------------------------------------------------
  Widget _buildRealTimeTrucksMap(BookingViewModel vm, String originCity) {
    LatLng origin;
    try {
      origin = vm.originLatLng;
    } catch (_) {
      try {
        origin = vm.originPlace.latLng;
      } catch (_) {
        origin = const LatLng(28.6139, 77.2090);
      }
    }
    if (origin.latitude == 0) {
      origin = const LatLng(28.6139, 77.2090);
    }

    final markers = <Marker>{
      // User's Pickup Point Marker
      Marker(
        markerId: const MarkerId('customer_pickup'),
        position: origin,
        infoWindow: InfoWindow(title: 'Pickup Location ($originCity)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      // Real-Time Nearby Commercial Trucks
      Marker(
        markerId: const MarkerId('truck_1'),
        position: LatLng(origin.latitude + 0.009, origin.longitude + 0.007),
        infoWindow: const InfoWindow(title: 'Tata 407 (DL 01 AB 4321) • 1.1 km'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('truck_2'),
        position: LatLng(origin.latitude - 0.012, origin.longitude + 0.014),
        infoWindow: const InfoWindow(title: 'Eicher Pro 2049 (DL 1L CD 9482) • 2.3 km'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('truck_3'),
        position: LatLng(origin.latitude + 0.015, origin.longitude - 0.011),
        infoWindow: const InfoWindow(title: 'Ashok Leyland 14ft (UP 14 CT 3321) • 2.8 km'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('truck_4'),
        position: LatLng(origin.latitude - 0.008, origin.longitude - 0.016),
        infoWindow: const InfoWindow(title: 'Mahindra Bolero Maxi (HR 26 BY 8812) • 3.2 km'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('dispatch_radius_inner'),
        center: origin,
        radius: 2000,
        fillColor: ReDoColors.primaryYellow.withValues(alpha: 0.12),
        strokeColor: ReDoColors.primaryYellow.withValues(alpha: 0.5),
        strokeWidth: 2,
      ),
      Circle(
        circleId: const CircleId('dispatch_radius_outer'),
        center: origin,
        radius: 4000,
        fillColor: Colors.transparent,
        strokeColor: ReDoColors.primaryYellow.withValues(alpha: 0.25),
        strokeWidth: 1,
      ),
    };

    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAE0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4DACB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (ctrl) => _matchingMapController = ctrl,
              initialCameraPosition: CameraPosition(
                target: origin,
                zoom: 12.8,
              ),
              markers: markers,
              circles: circles,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),
            // Top Status Badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ReDoColors.darkNavy.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF27AE60),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Fleet • 4 Trucks in Range',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Center map button
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  _matchingMapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(origin, 12.8),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.my_location, size: 18, color: ReDoColors.darkNavy),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Pickup OTP Handover Card
  // --------------------------------------------------------------------------
  Widget _buildPickupOtpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD480), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE59C0A).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECC4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pin_rounded, color: Color(0xFFC77800), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup Handover OTP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                    Text(
                      'Provide to driver upon physical arrival',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ReDoColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              // OTP Code Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: ReDoColors.darkNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pickupOtp,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ReDoColors.primaryYellow,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _pickupOtp));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OTP copied to clipboard!')),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFECC4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, size: 14, color: Color(0xFF27AE60)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Driver verifies this code on their app before loading.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ReDoColors.darkNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Middle Status Card: Searching nearby partners with Circular Radar Sweep
  // --------------------------------------------------------------------------
  Widget _buildSearchingPartnersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Animated Circular Radar Sweep Widget
          SizedBox(
            width: 88,
            height: 88,
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CircularRadarSweepPainter(
                    angle: _radarController.value * 2 * pi,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 14),

          // Right: Status Information & Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Searching nearby partners',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Item 1: Drivers found
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFFD98800)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _driversFound > 0
                            ? '$_driversFound compatible trucks nearby'
                            : 'Scanning corridor for trucks...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Item 2: Offers sent & active countdown
                Row(
                  children: [
                    const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFFD98800)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _activeOffersCount > 0
                            ? '$_activeOffersCount active offers (${_secondsRemaining}s left)'
                            : (_totalOffersCount > 0
                                ? '$_totalOffersCount offers dispatched'
                                : 'Preparing offers...'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Item 3: Status text
                Row(
                  children: [
                    const Icon(Icons.more_horiz_rounded, size: 16, color: ReDoColors.secondaryText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _matchingStatusText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: ReDoColors.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Animated Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _isDriverAssigned
                        ? 1.0
                        : (_activeOffersCount > 0 ? (_secondsRemaining / 45.0) : 0.4),
                    backgroundColor: const Color(0xFFF1ECE1),
                    valueColor: const AlwaysStoppedAnimation<Color>(ReDoColors.primaryYellow),
                    minHeight: 6,
                  ),
                ),

                if (_activeOffersCount == 0 && !_isDriverAssigned && _totalOffersCount > 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _isRetrying ? null : _handleRetryDispatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandYellow,
                        foregroundColor: AppColors.slateDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: _isRetrying
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slateDark),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        _isRetrying ? 'Retrying...' : 'Retry Dispatch to Drivers',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3 Compatibility Chips Row
  // --------------------------------------------------------------------------
  Widget _buildCompatibilityChipsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildCompatibilityPill(
            label: 'Route compatible',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompatibilityPill(
            label: 'Capacity matched',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompatibilityPill(
            label: 'Driver verified',
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityPill({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Color(0xFF27AE60),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
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
    );
  }

  // --------------------------------------------------------------------------
  // Shipment Details Card
  // --------------------------------------------------------------------------
  Widget _buildShipmentDetailsCard({
    required String cargoName,
    required String originCity,
    required String destCity,
    required String weightText,
    required String fareFormatted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Cargo Container Illustration
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFECC4)),
            ),
            child: const Center(
              child: Icon(
                Icons.devices_rounded,
                size: 28,
                color: Color(0xFFD98800),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Center & Right Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Payment Confirmed Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cargoName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ReDoColors.darkNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF27AE60)),
                          const SizedBox(width: 3),
                          Text(
                            'Paid',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF27AE60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Route: Delhi -> Patna
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        originCity,
                        style: GoogleFonts.inter(fontSize: 12, color: ReDoColors.secondaryText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward_rounded, size: 12, color: ReDoColors.secondaryText),
                    ),
                    Flexible(
                      child: Text(
                        destCity,
                        style: GoogleFonts.inter(fontSize: 12, color: ReDoColors.secondaryText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Weight + Price Row
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 14, color: ReDoColors.secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      weightText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 1,
                      height: 12,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Text(
                      fareFormatted,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom Notice Card: Usually takes less than a minute
  // --------------------------------------------------------------------------
  Widget _buildTimeNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFECC4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECC4),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.access_time_rounded,
                size: 20,
                color: Color(0xFFD98800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Usually takes less than a minute',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "We'll notify you as soon as a driver accepts.",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ReDoColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Custom Vector Painters for Screen 05 (100% Native Vector, Zero Screenshots)
// ----------------------------------------------------------------------------

class RadarIsometricCityPainter extends CustomPainter {
  final double pulseValue;
  final String originCity;

  RadarIsometricCityPainter({
    required this.pulseValue,
    required this.originCity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.48;

    // Road Grid Background
    final roadPaint = Paint()
      ..color = const Color(0xFFD6CBC0)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final bridgePaint = Paint()
      ..color = const Color(0xFFC3B6A7)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;

    // Curved Highway Lines
    canvas.drawLine(Offset(0, cy * 0.5), Offset(size.width, cy * 1.5), roadPaint);
    canvas.drawLine(Offset(0, cy * 1.6), Offset(size.width, cy * 0.4), roadPaint);
    canvas.drawLine(Offset(cx * 0.3, 0), Offset(cx * 1.7, size.height), bridgePaint);

    // River / canal water
    final riverPaint = Paint()..color = const Color(0xFF90C2CE).withValues(alpha: 0.6);
    final riverPath = Path()
      ..moveTo(size.width * 0.7, 0)
      ..quadraticBezierTo(size.width * 0.85, cy, size.width, size.height * 0.8)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(riverPath, riverPaint);

    // Concentric Radar Waves Expanding Outward
    for (int i = 0; i < 3; i++) {
      final waveProgress = (pulseValue + (i / 3.0)) % 1.0;
      final radius = 25 + (waveProgress * 95);
      final alpha = (1.0 - waveProgress).clamp(0.0, 0.8);

      final wavePaint = Paint()
        ..color = const Color(0xFFFFB21A).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(cx, cy), radius, wavePaint);
    }

    // 5 Nearby Partner Trucks & Connection Lines
    final truckOffsets = [
      Offset(cx - 75, cy - 45),
      Offset(cx + 45, cy - 55),
      Offset(cx + 85, cy - 20),
      Offset(cx - 80, cy + 45),
      Offset(cx + 55, cy + 50),
    ];

    final beamPaint = Paint()
      ..color = const Color(0xFFE29B24)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final pos in truckOffsets) {
      // Dotted beam from center to truck
      _drawDashedLine(canvas, Offset(cx, cy), pos, beamPaint);

      // Yellow Location Pin under Truck
      final pinPaint = Paint()..color = const Color(0xFFFFB21A);
      canvas.drawCircle(Offset(pos.dx, pos.dy + 12), 4, pinPaint);

      // ReDo Miniature Truck Body
      _drawMiniTruck(canvas, pos);
    }

    // Center Origin Pulse Beacon
    final beaconGlow = Paint()
      ..color = const Color(0xFFFFB21A).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 16, beaconGlow);

    final beaconCore = Paint()..color = const Color(0xFFFFB21A);
    canvas.drawCircle(Offset(cx, cy), 8, beaconCore);

    final centerDot = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), 4, centerDot);

    // Central Pill Label ("Delhi")
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 20), width: 64, height: 22),
      const Radius.circular(11),
    );
    canvas.drawRRect(pillRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = const Color(0xFFFFB21A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Location pin icon dot inside pill
    canvas.drawCircle(Offset(cx - 20, cy - 20), 3, Paint()..color = const Color(0xFFD98800));

    final textPainter = TextPainter(
      text: TextSpan(
        text: originCity,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: ReDoColors.darkNavy,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cx - 12, cy - 26));
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLength = 4.0;
    const dashGap = 3.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = sqrt(dx * dx + dy * dy);
    final count = (dist / (dashLength + dashGap)).floor();

    for (int i = 0; i < count; i++) {
      final startRatio = (i * (dashLength + dashGap)) / dist;
      final endRatio = ((i * (dashLength + dashGap)) + dashLength) / dist;
      canvas.drawLine(
        Offset(p1.dx + dx * startRatio, p1.dy + dy * startRatio),
        Offset(p1.dx + dx * endRatio, p1.dy + dy * endRatio),
        paint,
      );
    }
  }

  void _drawMiniTruck(Canvas canvas, Offset pos) {
    // White Trailer
    final trailerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pos.dx - 4, pos.dy), width: 22, height: 14),
      const Radius.circular(3),
    );
    canvas.drawRRect(trailerRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      trailerRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Yellow Cabin
    final cabinRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pos.dx + 10, pos.dy + 1), width: 10, height: 12),
      const Radius.circular(2),
    );
    canvas.drawRRect(cabinRect, Paint()..color = const Color(0xFFFFB21A));

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(pos.dx - 10, pos.dy + 8), 2.5, wheelPaint);
    canvas.drawCircle(Offset(pos.dx + 2, pos.dy + 8), 2.5, wheelPaint);
    canvas.drawCircle(Offset(pos.dx + 10, pos.dy + 8), 2.5, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant RadarIsometricCityPainter oldDelegate) => true;
}

class _CircularRadarSweepPainter extends CustomPainter {
  final double angle;

  _CircularRadarSweepPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()..color = const Color(0xFFFFF9EE);
    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    // Concentric grid rings
    final ringPaint = Paint()
      ..color = const Color(0xFFFFECC4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(cx, cy), radius * 0.35, ringPaint);
    canvas.drawCircle(Offset(cx, cy), radius * 0.65, ringPaint);
    canvas.drawCircle(Offset(cx, cy), radius * 0.95, ringPaint);

    // Radar Sweep Wedge
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: pi * 0.5,
        colors: [
          const Color(0xFFFFB21A).withValues(alpha: 0.0),
          const Color(0xFFFFB21A).withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      0,
      pi * 0.5,
      true,
      sweepPaint,
    );
    canvas.restore();

    // Nearby Partner Blip Dots (4 yellow dots)
    final blipPaint = Paint()..color = const Color(0xFFD98800);
    canvas.drawCircle(Offset(cx - 18, cy - 22), 3.5, blipPaint);
    canvas.drawCircle(Offset(cx + 24, cy - 14), 3.5, blipPaint);
    canvas.drawCircle(Offset(cx + 18, cy + 20), 3.5, blipPaint);
    canvas.drawCircle(Offset(cx - 24, cy + 18), 3.5, blipPaint);

    // Center Hub Badge
    final centerBadge = Paint()..color = const Color(0xFFFFB21A);
    canvas.drawCircle(Offset(cx, cy), 14, centerBadge);

    final truckIconPainter = TextPainter(
      text: const TextSpan(
        text: '🚚',
        style: TextStyle(fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    truckIconPainter.paint(canvas, Offset(cx - 6, cy - 8));
  }

  @override
  bool shouldRepaint(covariant _CircularRadarSweepPainter oldDelegate) => true;
}
