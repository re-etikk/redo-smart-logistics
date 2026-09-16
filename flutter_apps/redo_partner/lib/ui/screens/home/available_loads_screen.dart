import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/routing_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/unit_formatter.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../../viewmodels/theme_viewmodel.dart';
import '../../widgets/instant_load_alert_banner.dart';
import '../misc/notifications_screen.dart';
import '../chat/direct_chat_screen.dart';
import '../settings/partner_settings_screen.dart';

const _cityLatLng = <String, LatLng>{
  'Mumbai': LatLng(19.0760, 72.8777),
  'Delhi NCR': LatLng(28.6139, 77.2090),
  'Delhi': LatLng(28.6139, 77.2090),
  'Noida': LatLng(28.5355, 77.3910),
  'Pune': LatLng(18.5204, 73.8567),
  'Jaipur': LatLng(26.9124, 75.7873),
  'Surat': LatLng(21.1702, 72.8311),
  'Ahmedabad': LatLng(23.0225, 72.5714),
  'Bengaluru': LatLng(12.9716, 77.5946),
  'Chennai': LatLng(13.0827, 80.2707),
  'Kolkata': LatLng(22.5726, 88.3639),
  'Hyderabad': LatLng(17.3850, 78.4867),
  'Lucknow': LatLng(26.8467, 80.9462),
  'Kanpur': LatLng(26.4499, 80.3319),
  'Patna': LatLng(25.5941, 85.1376),
  'Indore': LatLng(22.7196, 75.8577),
  'Nagpur': LatLng(21.1458, 79.0882),
  'Chandigarh': LatLng(30.7333, 76.7794),
  'Ludhiana': LatLng(30.9010, 75.8573),
};

class AvailableLoadsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTrips;
  const AvailableLoadsScreen({super.key, this.onNavigateToTrips});

  @override
  State<AvailableLoadsScreen> createState() => _AvailableLoadsScreenState();
}

class _AvailableLoadsScreenState extends State<AvailableLoadsScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  GoogleMapController? _mapController;

  List<PlaceSuggestion> _fromSuggestions = [];
  List<PlaceSuggestion> _toSuggestions = [];
  Timer? _debounceFrom;
  Timer? _debounceTo;

  LatLng? _fromLatLng;
  LatLng? _toLatLng;
  LatLng? _driverCurrentLatLng;

  RouteInfo? _currentRoute;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _showMap = true;
  bool _locatingDriver = false;

  // Active status toggles
  bool _isReadyForLoads = true;
  bool _isGpsSharingOn = true;

  // Category filter
  String _selectedCategory = 'All Loads'; // 'All Loads', 'Instant', 'Scheduled', 'Best Match'
  String _selectedTonnage = 'All'; // 'All', '< 3T', '3 - 10T', '10T+'

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (mounted) {
        final vm = context.read<PartnerTripsViewModel>();
        await vm.fetchAll();
        _fetchAndZoomCurrentLocation();
      }
    });
  }

  Future<void> _fetchAndZoomCurrentLocation({bool animate = false}) async {
    setState(() => _locatingDriver = true);
    try {
      Position? pos;
      final hasPerm = await Geolocator.checkPermission();
      if (hasPerm == LocationPermission.always || hasPerm == LocationPermission.whileInUse) {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 4));
      } else {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.always || req == LocationPermission.whileInUse) {
          pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 4));
        }
      }

      if (pos != null && mounted) {
        final driverLoc = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _driverCurrentLatLng = driverLoc;
          _fromLatLng ??= driverLoc;
          _markers.removeWhere((m) => m.markerId.value == 'driver_live');
          _markers.add(
            Marker(
              markerId: const MarkerId('driver_live'),
              position: driverLoc,
              infoWindow: const InfoWindow(title: 'Your Truck Live Location (GPS)'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          );
        });

        if (animate && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: driverLoc, zoom: 15.0),
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _locatingDriver = false);
    }
  }

  void _onFromChanged(String q) {
    _debounceFrom?.cancel();
    _debounceFrom = Timer(const Duration(milliseconds: 250), () async {
      if (q.trim().isEmpty) {
        setState(() => _fromSuggestions = []);
        _updateFilterAndRoute();
        return;
      }
      try {
        final res = await RoutingService.searchPlaces(q);
        if (mounted) setState(() => _fromSuggestions = res);
      } catch (_) {}
    });
  }

  void _onToChanged(String q) {
    _debounceTo?.cancel();
    _debounceTo = Timer(const Duration(milliseconds: 250), () async {
      if (q.trim().isEmpty) {
        setState(() => _toSuggestions = []);
        _updateFilterAndRoute();
        return;
      }
      try {
        final res = await RoutingService.searchPlaces(q);
        if (mounted) setState(() => _toSuggestions = res);
      } catch (_) {}
    });
  }

  void _swapLocations() {
    final tempText = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = tempText;

    final tempLatLng = _fromLatLng;
    _fromLatLng = _toLatLng;
    _toLatLng = tempLatLng;

    _updateFilterAndRoute();
  }

  void _selectRoute(String from, String to) {
    _fromController.text = from;
    _toController.text = to;
    _fromLatLng = _resolveCoord(from);
    _toLatLng = _resolveCoord(to);
    _fromSuggestions = [];
    _toSuggestions = [];
    _showMap = true;
    _updateFilterAndRoute();
  }

  LatLng _resolveCoord(String cityName) {
    for (final entry in _cityLatLng.entries) {
      if (cityName.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(cityName.toLowerCase())) {
        return entry.value;
      }
    }
    return const LatLng(28.6139, 77.2090); // Default to Delhi NCR hub
  }

  void _updateFilterAndRoute() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    final tripsVM = context.read<PartnerTripsViewModel>();

    if (from.isNotEmpty && to.isNotEmpty) {
      tripsVM.setRouteSearch(from: from, to: to);
      _calculateAndShowRoute();
    } else if (to.isNotEmpty) {
      tripsVM.setRouteSearch(from: '', to: to);
      _calculateAndShowRoute();
    } else if (from.isNotEmpty) {
      tripsVM.setRouteSearch(from: from, to: '');
      _calculateAndShowRoute();
    } else {
      tripsVM.clearFilters();
      setState(() {
        _currentRoute = null;
        _polylines = {};
        _markers.removeWhere((m) => m.markerId.value != 'driver_live');
      });
    }
  }

  Future<void> _calculateAndShowRoute() async {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    if (from.isEmpty && to.isEmpty) return;

    final start = _fromLatLng ?? (from.isNotEmpty ? _resolveCoord(from) : (_driverCurrentLatLng ?? const LatLng(28.6139, 77.2090)));
    final end = _toLatLng ?? (to.isNotEmpty ? _resolveCoord(to) : start);

    if (from.isNotEmpty && to.isNotEmpty) {
      try {
        final route = await RoutingService.getDrivingRoute(start, end);
        if (!mounted || route == null) return;

        final polyline = Polyline(
          polylineId: const PolylineId('selected_corridor'),
          points: route.points,
          color: AppColors.brandYellow,
          width: 5,
        );

        final markers = <Marker>{
          if (_driverCurrentLatLng != null)
            Marker(
              markerId: const MarkerId('driver_live'),
              position: _driverCurrentLatLng!,
              infoWindow: const InfoWindow(title: 'Your Truck Live Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          Marker(
            markerId: const MarkerId('origin'),
            position: start,
            infoWindow: InfoWindow(title: 'Pickup: $from'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: end,
            infoWindow: InfoWindow(title: 'Drop: $to'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };

        setState(() {
          _currentRoute = route;
          _polylines = {polyline};
          _markers = markers;
        });

        if (_mapController != null && route.points.isNotEmpty) {
          final bounds = _computeBounds([start, end, ...route.points]);
          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        }
      } catch (_) {}
    } else if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(start, 11.0));
    }
  }

  LatLngBounds _computeBounds(List<LatLng> points) {
    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (final p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  @override
  void dispose() {
    _debounceFrom?.cancel();
    _debounceTo?.cancel();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.watch<PartnerTripsViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode(context);
    final isMetric = themeVM.isMetric;

    // Theme-Aware Dynamic Palette
    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final cardAltBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textMuted = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    // Filter loads according to Category & Tonnage
    List<AvailableLoad> displayedLoads = tripsVM.availableLoads;
    if (_selectedCategory == 'Instant') {
      displayedLoads = displayedLoads.where((l) => l.isInstant).toList();
    } else if (_selectedCategory == 'Scheduled') {
      displayedLoads = displayedLoads.where((l) => !l.isInstant).toList();
    } else if (_selectedCategory == 'Best Match') {
      displayedLoads = displayedLoads.where((l) => l.matchScore >= 70 || l.hasRealMatchScore).toList();
    }

    if (_selectedTonnage == '< 3T') {
      displayedLoads = displayedLoads.where((l) => l.weightTons < 3.0).toList();
    } else if (_selectedTonnage == '3 - 10T') {
      displayedLoads = displayedLoads.where((l) => l.weightTons >= 3.0 && l.weightTons <= 10.0).toList();
    } else if (_selectedTonnage == '10T+') {
      displayedLoads = displayedLoads.where((l) => l.weightTons > 10.0).toList();
    }

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP COCKPIT HEADER WITH ORIGINAL "R" LOGO
            _buildTopHeader(context, isDark, cardBg, textPrimary, textSecondary, cardBorder),

            // Main Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandYellow,
                backgroundColor: cardBg,
                onRefresh: () async {
                  await tripsVM.fetchAll();
                  await _fetchAndZoomCurrentLocation();
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Instant load alert banner (if active)
                    if (tripsVM.instantLoadAlert != null) ...[
                      InstantLoadAlertBanner(
                        secondsRemaining: tripsVM.instantSecondsRemaining,
                        load: tripsVM.instantLoadAlert!,
                        onAccept: () async {
                          final load = tripsVM.instantLoadAlert!;
                          final id = await tripsVM.acceptLoad(load);
                          if (id != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Instant Load Accepted! Booking: $id')),
                            );
                          }
                        },
                        onDecline: () => tripsVM.declineInstantLoad(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 2. HERO BANNER WITH CUSTOM COMMERCIAL TRUCK
                    _buildHeroBanner(isDark),
                    const SizedBox(height: 12),

                    // 3. DUAL STATUS STRIP (READY FOR LOADS + GPS LIVE TRACKING)
                    _buildStatusCardsRow(isDark, cardBorder),
                    const SizedBox(height: 12),

                    // 4. SEARCH / ROUTE INTERCEPTION CARD
                    _buildSearchCard(isDark, cardBg, cardAltBg, cardBorder, textPrimary, textSecondary, textMuted, isMetric),
                    const SizedBox(height: 14),

                    // 5. INTERACTIVE HIGHWAY RADAR & ROUTE MAP CARD
                    _buildInteractiveMapCard(isDark, cardBg, cardBorder, textPrimary, textSecondary),
                    const SizedBox(height: 16),

                    // 6. QUICK TOOLS 4-ACTION GRID
                    _buildQuickToolsGrid(context, isDark, cardBg, cardBorder, textPrimary, textSecondary),
                    const SizedBox(height: 16),

                    // 7. DRIVE YOUR SUCCESS SECTION
                    _buildDriveYourSuccess(context, displayedLoads.length, isDark, cardBg, cardAltBg, cardBorder, textPrimary, textSecondary, tripsVM),
                    const SizedBox(height: 16),

                    // 8. REDO REWARDS BANNER
                    _buildRewardsBanner(context, isDark),
                    const SizedBox(height: 20),

                    // 9. FEATURED LOADS NEAR YOU HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Loads Near You',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'All Loads';
                              _selectedTonnage = 'All';
                              _fromController.clear();
                              _toController.clear();
                            });
                            tripsVM.clearFilters();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Showing all available nationwide loads')),
                            );
                          },
                          child: Text(
                            'See All >',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandYellowDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // FEATURED LOADS FEED
                    if (tripsVM.isLoading && tripsVM.availableLoads.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppColors.brandYellow),
                        ),
                      )
                    else if (displayedLoads.isEmpty)
                      _buildEmptyLoadsState(isDark, cardBg, cardBorder, textPrimary, textSecondary)
                    else
                      ...displayedLoads.map((load) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLoadCard(load, currency, isMetric, isDark, cardBg, cardBorder, textPrimary, textSecondary),
                          )),

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

  // --- 1. TOP COCKPIT HEADER WITH ORIGINAL "R" LOGO ---
  Widget _buildTopHeader(BuildContext context, bool isDark, Color cardBg, Color textPrimary, Color textSecondary, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? const Color(0xFF0B0F19) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Official Original "R" Logo + REDO typography (Replacing generic yellow pill)
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/partner_logo.png',
                    height: 38,
                    width: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'R',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'REDO',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Move More Together',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right Cockpit Status & Action Icons
          Row(
            children: [
              // Metric / Unit Indicator Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_rupee, size: 12, color: AppColors.brandYellowDark),
                    const SizedBox(width: 2),
                    Text(
                      'INR • KM',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Notifications Icon
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBorder),
                  ),
                  child: Stack(
                    children: [
                      Icon(Icons.notifications_none_outlined, size: 18, color: textPrimary),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Settings Gear Button
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PartnerSettingsScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBorder),
                  ),
                  child: Icon(Icons.settings_outlined, size: 18, color: textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. HERO BANNER WITH CUSTOM COMMERCIAL TRUCK ---
  Widget _buildHeroBanner(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Commercial Freight Truck Image Asset
          Image.asset(
            'assets/images/partner_hero_truck_banner.jpg',
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
            ),
          ),

          // High Contrast Gradient Overlay
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Left Typography Banner
          Positioned(
            left: 16,
            top: 22,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'More Loads.\nBigger Opportunities.',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    shadows: [
                      const Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find. Bid. Move. Grow with REDO.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),

          // Right Tagline Script
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Drivers • Partners\nA Stronger Tomorrow',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: AppColors.brandYellow,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. DUAL STATUS STRIP (READY FOR LOADS + GPS LIVE TRACKING) ---
  Widget _buildStatusCardsRow(bool isDark, Color cardBorder) {
    return Row(
      children: [
        // Left: Ready for Loads
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() => _isReadyForLoads = !_isReadyForLoads);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isReadyForLoads ? 'You are now visible to shippers nationwide' : 'Status set to Offline'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: _isReadyForLoads
                    ? (isDark ? const Color(0xFF0C2419) : const Color(0xFFDCFCE7))
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isReadyForLoads ? const Color(0xFF10B981).withValues(alpha: 0.4) : cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isReadyForLoads ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                      boxShadow: _isReadyForLoads
                          ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready for Loads',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _isReadyForLoads ? (isDark ? Colors.white : const Color(0xFF14532D)) : const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          _isReadyForLoads ? 'Online & Visible' : 'Offline',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _isReadyForLoads ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Right: GPS Live Tracking
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() => _isGpsSharingOn = !_isGpsSharingOn);
              _fetchAndZoomCurrentLocation(animate: true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isGpsSharingOn ? 'GPS Live Tracking Active • Pinging highway radar' : 'GPS Tracking Paused'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: _isGpsSharingOn
                    ? (isDark ? const Color(0xFF0F1E36) : const Color(0xFFE0F2FE))
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isGpsSharingOn ? const Color(0xFF0284C7).withValues(alpha: 0.4) : cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isGpsSharingOn ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                      boxShadow: _isGpsSharingOn
                          ? [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPS Live Tracking',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _isGpsSharingOn ? (isDark ? Colors.white : const Color(0xFF0369A1)) : const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          _isGpsSharingOn ? 'Live Telemetry' : 'Inactive',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _isGpsSharingOn ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 4. SEARCH / ROUTE INTERCEPTION CARD ---
  Widget _buildSearchCard(
    bool isDark,
    Color cardBg,
    Color cardAltBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    bool isMetric,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup & Destination Inputs with Swap Button
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Column(
                children: [
                  // Pickup Location Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardAltBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_checked, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Location / Current City',
                                style: GoogleFonts.inter(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                              ),
                              TextField(
                                controller: _fromController,
                                onChanged: _onFromChanged,
                                style: GoogleFonts.inter(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'Enter origin (e.g. Delhi, Mumbai)',
                                  hintStyle: TextStyle(color: textMuted, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_fromController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            color: textMuted,
                            onPressed: () {
                              _fromController.clear();
                              _fromLatLng = null;
                              _updateFilterAndRoute();
                            },
                          ),
                        IconButton(
                          icon: _locatingDriver
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandYellow))
                              : const Icon(Icons.my_location, size: 18, color: AppColors.brandYellowDark),
                          tooltip: 'Detect My Location',
                          onPressed: () => _fetchAndZoomCurrentLocation(animate: true),
                        ),
                        const SizedBox(width: 32), // Space for floating swap button
                      ],
                    ),
                  ),

                  // Dotted connector
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        children: [
                          Container(width: 2, height: 4, color: cardBorder),
                          const SizedBox(height: 2),
                          Container(width: 2, height: 4, color: cardBorder),
                        ],
                      ),
                    ),
                  ),

                  // Destination Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardAltBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Color(0xFFEF4444)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To City / Destination Hub',
                                style: GoogleFonts.inter(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                              ),
                              TextField(
                                controller: _toController,
                                onChanged: _onToChanged,
                                style: GoogleFonts.inter(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'Search city or corridor destination',
                                  hintStyle: TextStyle(color: textMuted, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_toController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            color: textMuted,
                            onPressed: () {
                              _toController.clear();
                              _toLatLng = null;
                              _updateFilterAndRoute();
                            },
                          ),
                        const SizedBox(width: 32), // Space for floating swap button
                      ],
                    ),
                  ),
                ],
              ),

              // Floating Tactile Swap Button on Right
              Positioned(
                right: 4,
                child: InkWell(
                  onTap: _swapLocations,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cardAltBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.swap_vert, color: AppColors.brandYellowDark, size: 20),
                  ),
                ),
              ),
            ],
          ),

          // Autocomplete Dropdown suggestions (if user is typing)
          if (_fromSuggestions.isNotEmpty || _toSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: cardAltBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                ],
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_fromSuggestions.isNotEmpty)
                    ..._fromSuggestions.map((s) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.place, color: Color(0xFF10B981), size: 16),
                          title: Text(s.name, style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                          subtitle: Text(s.description, style: TextStyle(color: textSecondary, fontSize: 10)),
                          onTap: () {
                            setState(() {
                              _fromController.text = s.name;
                              _fromLatLng = s.latLng;
                              _fromSuggestions = [];
                            });
                            _updateFilterAndRoute();
                          },
                        )),
                  if (_toSuggestions.isNotEmpty)
                    ..._toSuggestions.map((s) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.place, color: Color(0xFFEF4444), size: 16),
                          title: Text(s.name, style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                          subtitle: Text(s.description, style: TextStyle(color: textSecondary, fontSize: 10)),
                          onTap: () {
                            setState(() {
                              _toController.text = s.name;
                              _toLatLng = s.latLng;
                              _toSuggestions = [];
                            });
                            _updateFilterAndRoute();
                          },
                        )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Route Shortcut Chips (Delhi ⇄ Mumbai, Mumbai ⇄ Pune, Bengaluru ⇄ Chennai, + More)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRouteChip('Delhi ⇄ Mumbai', 'Delhi', 'Mumbai', cardAltBg, cardBorder, textSecondary),
                const SizedBox(width: 8),
                _buildRouteChip('Mumbai ⇄ Pune', 'Mumbai', 'Pune', cardAltBg, cardBorder, textSecondary),
                const SizedBox(width: 8),
                _buildRouteChip('Bengaluru ⇄ Chennai', 'Bengaluru', 'Chennai', cardAltBg, cardBorder, textSecondary),
                const SizedBox(width: 8),
                _buildRouteChip('Delhi ⇄ Jaipur', 'Delhi', 'Jaipur', cardAltBg, cardBorder, textSecondary),
                const SizedBox(width: 8),
                _buildRouteChip('Ahmedabad ⇄ Surat', 'Ahmedabad', 'Surat', cardAltBg, cardBorder, textSecondary),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Category Pills: All Loads, Instant, Scheduled, Best Match
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill('All Loads', cardAltBg, cardBorder, textSecondary),
                const SizedBox(width: 8),
                _buildCategoryPill('Instant', cardAltBg, cardBorder, textSecondary),
                const SizedBox(width: 8),
                _buildCategoryPill('Scheduled', cardAltBg, cardBorder, textSecondary),
                const SizedBox(width: 8),
                _buildCategoryPill('Best Match', cardAltBg, cardBorder, textSecondary),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tonnage Filter Pills: All, < 3T, 3 - 10T, 10T+
          Row(
            children: [
              Text(
                'Tonnage:',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTonnageChip('All', cardAltBg, cardBorder, textSecondary),
                    _buildTonnageChip('< 3T', cardAltBg, cardBorder, textSecondary),
                    _buildTonnageChip('3 - 10T', cardAltBg, cardBorder, textSecondary),
                    _buildTonnageChip('10T+', cardAltBg, cardBorder, textSecondary),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Big Bright Yellow "Search Loads" CTA Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.slateDark,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                _updateFilterAndRoute();
                final from = _fromController.text.trim();
                final to = _toController.text.trim();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      from.isNotEmpty && to.isNotEmpty
                          ? 'Searching loads for corridor: $from ➔ $to'
                          : (from.isNotEmpty ? 'Searching loads around $from' : 'Showing all verified freight loads'),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 20, color: AppColors.slateDark),
                  const SizedBox(width: 8),
                  Text(
                    'Search Loads',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.slateDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteChip(String label, String from, String to, Color cardAltBg, Color cardBorder, Color textSecondary) {
    final isSel = _fromController.text.toLowerCase().contains(from.toLowerCase()) &&
        _toController.text.toLowerCase().contains(to.toLowerCase());

    return InkWell(
      onTap: () => _selectRoute(from, to),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.brandYellow.withValues(alpha: 0.2) : cardAltBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? AppColors.brandYellowDark : cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? AppColors.brandYellowDark : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String label, Color cardAltBg, Color cardBorder, Color textSecondary) {
    final isSel = _selectedCategory == label;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.brandYellow : cardAltBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? AppColors.brandYellow : cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? AppColors.slateDark : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTonnageChip(String label, Color cardAltBg, Color cardBorder, Color textSecondary) {
    final isSel = _selectedTonnage == label;
    return InkWell(
      onTap: () => setState(() => _selectedTonnage = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? AppColors.brandYellow.withValues(alpha: 0.2) : cardAltBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? AppColors.brandYellowDark : cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? AppColors.brandYellowDark : textSecondary,
          ),
        ),
      ),
    );
  }

  // --- 5. INTERACTIVE HIGHWAY RADAR & ROUTE MAP CARD ---
  Widget _buildInteractiveMapCard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with collapse/expand toggle & Locate Me
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar, size: 18, color: AppColors.brandYellowDark),
                    const SizedBox(width: 8),
                    Text(
                      'Corridor Radar & Live Route',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _fetchAndZoomCurrentLocation(animate: true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, size: 14, color: AppColors.brandYellowDark),
                            const SizedBox(width: 4),
                            Text('Locate', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandYellowDark)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_showMap ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: textSecondary, size: 20),
                      onPressed: () => setState(() => _showMap = !_showMap),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_showMap)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _fromLatLng ?? _driverCurrentLatLng ?? const LatLng(28.6139, 77.2090),
                        zoom: 12.0,
                      ),
                      polylines: _polylines,
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (c) {
                        _mapController = c;
                        if (_driverCurrentLatLng != null) {
                          c.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _driverCurrentLatLng!, zoom: 14.0)));
                        }
                      },
                    ),

                    // Top Right Controls (Recenter Corridor & Recenter GPS)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'map_gps_zoom_btn',
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            foregroundColor: AppColors.brandYellowDark,
                            elevation: 2,
                            onPressed: () => _fetchAndZoomCurrentLocation(animate: true),
                            child: const Icon(Icons.gps_fixed, size: 18),
                          ),
                          if (_currentRoute != null) ...[
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'map_route_zoom_btn',
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              foregroundColor: textPrimary,
                              elevation: 2,
                              onPressed: () {
                                if (_currentRoute != null && _currentRoute!.points.isNotEmpty) {
                                  final bounds = _computeBounds(_currentRoute!.points);
                                  _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                                }
                              },
                              child: const Icon(Icons.alt_route, size: 18),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Bottom Left Route Info Pill (if route is active)
                    if (_currentRoute != null)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '${_currentRoute!.distanceText} • Est: ${_currentRoute!.durationText}',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandYellow),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 6. QUICK TOOLS 4-ACTION GRID ---
  Widget _buildQuickToolsGrid(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        _buildToolCard(
          icon: Icons.notifications_active_outlined,
          hasDot: true,
          title: 'Load Alerts',
          subtitle: 'Instant chimes',
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () => _showLoadAlertsSheet(context, isDark, cardBg, textPrimary, cardBorder),
        ),
        const SizedBox(width: 8),
        _buildToolCard(
          icon: Icons.alt_route_outlined,
          title: 'Saved Routes',
          subtitle: 'Fast corridor',
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () => _showSavedRoutesSheet(context, isDark, cardBg, textPrimary, cardBorder),
        ),
        const SizedBox(width: 8),
        _buildToolCard(
          icon: Icons.gavel_outlined,
          title: 'My Bids',
          subtitle: 'Active quotes',
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () {
            widget.onNavigateToTrips?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switched to My Trips & Bids management')),
            );
          },
        ),
        const SizedBox(width: 8),
        _buildToolCard(
          icon: Icons.local_gas_station_outlined,
          title: 'Fuel Prices',
          subtitle: 'Daily diesel',
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () => _showFuelPricesDialog(context, isDark),
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    bool hasDot = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Icon(icon, size: 22, color: textPrimary),
                  if (hasDot)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 8, color: textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 7. DRIVE YOUR SUCCESS SECTION ---
  Widget _buildDriveYourSuccess(
    BuildContext context,
    int loadCount,
    bool isDark,
    Color cardBg,
    Color cardAltBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    PartnerTripsViewModel tripsVM,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drive Your Success',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Insights to help you earn more',
                    style: GoogleFonts.inter(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showDriveYourSuccessModal(context, tripsVM, isDark, textPrimary, cardBg, cardBorder),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'View All >',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandYellowDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Metric Tiles in 1 Row
          Row(
            children: [
              _buildMetricTile(
                icon: Icons.trending_up,
                iconColor: const Color(0xFF10B981),
                value: '${max(14, loadCount)}',
                label: 'New Loads Today',
                cardAltBg: cardAltBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${max(14, loadCount)} verified commercial loads currently available for dispatch')),
                ),
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                icon: Icons.currency_rupee,
                iconColor: const Color(0xFF38BDF8),
                value: '₹ 48,500',
                label: 'Avg. Rate (trip)',
                cardAltBg: cardAltBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Average trip revenue across top national freight corridors')),
                ),
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                icon: Icons.bar_chart,
                iconColor: const Color(0xFFA855F7),
                value: '95%',
                label: 'On-time Loadings',
                cardAltBg: cardAltBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your commercial on-time dispatch rate is 95% (Gold Tier)')),
                ),
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                icon: Icons.star,
                iconColor: AppColors.brandYellow,
                value: '4.8',
                label: 'Partner Rating',
                cardAltBg: cardAltBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verified Transporter Rating: 4.8 / 5.0 (Top 5% Drivers)')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color cardAltBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: cardAltBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: iconColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 8, color: textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 8. REDO REWARDS BANNER ---
  Widget _buildRewardsBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, size: 36, color: Color(0xFF78350F)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REDO Rewards',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete more trips • Earn fuel points • Unlock VIP tolls',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF451A03)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  title: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: AppColors.brandYellow),
                      const SizedBox(width: 8),
                      Text('REDO Rewards Club', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  content: Text(
                    '• Current Tier: Gold Transporter\n• Rewards Balance: 1,450 Fuel Points\n• Free Toll Passes: 4 Highway Fastags\n• Cash redemption rate: 1 pt = ₹1 Fuel Cashback.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
                  ],
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Know More', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 9. FEATURED LOAD CARD ---
  Widget _buildLoadCard(
    AvailableLoad load,
    NumberFormat currency,
    bool isMetric,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final weightStr = UnitFormatter.formatWeightTons(load.weightTons, isMetric: isMetric);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route + Time + Verified Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${load.origin} ➔ ${load.destination}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '2h ago',
                    style: GoogleFonts.inter(fontSize: 11, color: textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Specs Row: Cargo Type, Weight, Timing
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    load.cargoType,
                    style: GoogleFonts.inter(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Icon(Icons.scale_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    weightStr,
                    style: GoogleFonts.inter(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Today - Tomorrow',
                    style: GoogleFonts.inter(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: cardBorder),
          const SizedBox(height: 12),

          // Bottom Row: Price + View Details / Accept Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guaranteed Payout',
                    style: GoogleFonts.inter(fontSize: 9, color: textSecondary, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    currency.format(load.offeredPriceInr),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Direct Chat Button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DirectChatScreen(
                            bookingId: 'inquiry_${load.cargoId}',
                            counterpartyName: load.smeName.isNotEmpty ? load.smeName : 'Verified Shipper',
                            counterpartyRole: 'Shipper / Cargo Owner',
                            counterpartyPhone: '+91 98765 43210',
                            origin: load.origin,
                            destination: load.destination,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Icon(Icons.chat_bubble_outline, size: 18, color: textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Map route button
                  InkWell(
                    onTap: () => _selectRoute(load.origin, load.destination),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Icon(Icons.map_outlined, size: 18, color: AppColors.brandYellowDark),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // View Details / Accept Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: AppColors.slateDark,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => _showAcceptLoadModal(load, currency, isDark),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAcceptLoadModal(AvailableLoad load, NumberFormat currency, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool accepting = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Load Details & Dispatch',
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Corridor Route
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pickup: ${load.origin}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 12),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Destination: ${load.destination}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Specifications Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailSpecTile('Weight', '${load.weightTons} Tons', Icons.scale, isDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDetailSpecTile('Cargo Type', load.cargoType, Icons.inventory_2_outlined, isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailSpecTile('Shipper', load.smeName.isNotEmpty ? load.smeName : 'Verified Shipper', Icons.business, isDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDetailSpecTile('Loading', 'Today • Immediate', Icons.access_time, isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Guaranteed Total Payout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Guaranteed Net Payout:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      currency.format(load.offeredPriceInr),
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Accept CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: AppColors.slateDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: accepting
                        ? null
                        : () async {
                            setSheetState(() => accepting = true);
                            final vm = context.read<PartnerTripsViewModel>();
                            final bookingId = await vm.acceptLoad(load);

                            // Send positive reinforcement to Online Learning Engine
                            SupabaseService.sendRecommendationFeedback(
                              truckId: vm.myTrucks.isNotEmpty ? vm.myTrucks.first.truckId : 'trk_active',
                              cargoId: load.cargoId,
                              action: 'accept_load',
                              corridorKey: '${load.origin.toLowerCase()}->${load.destination.toLowerCase()}',
                            );

                            if (ctx.mounted) Navigator.pop(ctx);

                            if (context.mounted) {
                              if (bookingId != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ Load Accepted! Assigned Booking: $bookingId'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                widget.onNavigateToTrips?.call();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(vm.errorMessage ?? 'Could not accept load. Please try again.'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            }
                          },
                    child: accepting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.slateDark))
                        : Text('Accept Load & Start Trip', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSpecTile(String title, String val, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.brandYellowDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF94A3B8))),
                Text(val, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MODALS FOR QUICK ACTIONS & INSIGHTS ---

  void _showDriveYourSuccessModal(BuildContext context, PartnerTripsViewModel tripsVM, bool isDark, Color textPrimary, Color cardBg, Color cardBorder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Market Intelligence & Performance', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: textPrimary)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Real-time logistics supply-demand analytics across national corridors:',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            _buildInsightCorridorRow('Delhi NCR ➔ Mumbai', '₹48,500', 'High Volume 🔥', const Color(0xFF10B981)),
            _buildInsightCorridorRow('Mumbai ➔ Pune', '₹16,200', 'Fast Turnaround ⚡', const Color(0xFF38BDF8)),
            _buildInsightCorridorRow('Bengaluru ➔ Chennai', '₹24,800', 'Daily Direct 📦', const Color(0xFFA855F7)),
            _buildInsightCorridorRow('Delhi ➔ Jaipur', '₹18,500', 'Return Match 🔄', const Color(0xFFF59E0B)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.slateDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onNavigateToTrips?.call();
                },
                child: Text('View Full Trips & Bids', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCorridorRow(String corridor, String rate, String badge, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(corridor, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
          Row(
            children: [
              Text(rate, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: badgeColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLoadAlertsSheet(BuildContext context, bool isDark, Color cardBg, Color textPrimary, Color cardBorder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Instant Load Proximity Alerts', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: textPrimary)),
            const SizedBox(height: 6),
            Text('Configure radar notifications for high-paying loads near your truck:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            SwitchListTile(
              value: true,
              activeColor: AppColors.brandYellow,
              title: Text('Proximity Radar (Within 50 KM)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('Audio chimes when loads are posted near your live GPS', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
              onChanged: (v) {},
            ),
            SwitchListTile(
              value: true,
              activeColor: AppColors.brandYellow,
              title: Text('Return Trip Corridor Alerts', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('Prioritize backhaul loads returning to your home depot', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandYellow, foregroundColor: AppColors.slateDark),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Highway Radar Alert Preferences Saved!')),
                  );
                },
                child: const Text('Save Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedRoutesSheet(BuildContext context, bool isDark, Color cardBg, Color textPrimary, Color cardBorder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Saved Commercial Corridors', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: textPrimary)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.route, color: AppColors.brandYellowDark),
              title: const Text('Delhi NCR ⇄ Mumbai'),
              subtitle: const Text('NH-48 Corridor • 1,420 KM'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _selectRoute('Delhi', 'Mumbai');
              },
            ),
            ListTile(
              leading: const Icon(Icons.route, color: AppColors.brandYellowDark),
              title: const Text('Mumbai ⇄ Pune Expressway'),
              subtitle: const Text('Express Highway • 150 KM'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _selectRoute('Mumbai', 'Pune');
              },
            ),
            ListTile(
              leading: const Icon(Icons.route, color: AppColors.brandYellowDark),
              title: const Text('Bengaluru ⇄ Chennai'),
              subtitle: const Text('NH-48 Industrial Belt • 350 KM'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _selectRoute('Bengaluru', 'Chennai');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelPricesDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.local_gas_station, color: AppColors.brandYellowDark),
            const SizedBox(width: 8),
            Text('Live State Diesel Rates', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          '• Delhi NCR: ₹87.62 / L\n• Noida (UP): ₹87.96 / L\n• Mumbai (MH): ₹92.15 / L\n• Bengaluru (KA): ₹88.40 / L\n• Chennai (TN): ₹90.20 / L\n• Jaipur (RJ): ₹90.36 / L\n\nREDO Fleet Cardholders get instant ₹2.50/L cashback at all IndianOil & BPCL pumps.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildEmptyLoadsState(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_outlined, size: 48, color: AppColors.brandYellowDark),
          const SizedBox(height: 12),
          Text(
            'No matching loads found',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing your search query or switching to "All Loads".',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandYellow, foregroundColor: AppColors.slateDark),
            onPressed: () {
              setState(() {
                _selectedCategory = 'All Loads';
                _selectedTonnage = 'All';
                _fromController.clear();
                _toController.clear();
              });
              context.read<PartnerTripsViewModel>().clearFilters();
            },
            child: const Text('Clear Filters & Show All Loads'),
          ),
        ],
      ),
    );
  }
}
