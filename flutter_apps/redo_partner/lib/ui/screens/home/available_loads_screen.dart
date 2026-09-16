import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/unit_formatter.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/routing_service.dart';
import '../../../data/services/corridor_ml_service.dart';
import '../../../data/services/supabase_service.dart';
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
  'Noida (UP)': LatLng(28.5355, 77.3910),
  'Jaipur': LatLng(26.9124, 75.7873),
  'Jaipur (RJ)': LatLng(26.9124, 75.7873),
  'Bengaluru': LatLng(12.9716, 77.5946),
  'Pune': LatLng(18.5204, 73.8567),
  'Chennai': LatLng(13.0827, 80.2707),
  'Kolkata': LatLng(22.5726, 88.3639),
  'Hyderabad': LatLng(17.3850, 78.4867),
  'Ahmedabad': LatLng(23.0225, 72.5714),
  'Surat': LatLng(21.1702, 72.8311),
  'Lucknow': LatLng(26.8467, 80.9462),
  'Kanpur': LatLng(26.4499, 80.3319),
  'Patna': LatLng(25.5941, 85.1376),
  'Nagpur': LatLng(21.1458, 79.0882),
  'Indore': LatLng(22.7196, 75.8577),
  'Vadodara': LatLng(22.3072, 73.1812),
};

LatLng _resolveCoord(String city) {
  final resolved = RoutingService.getCoordinatesForCity(city);
  if (resolved != null) return resolved;
  for (final entry in _cityLatLng.entries) {
    if (city.toLowerCase().contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  return const LatLng(28.6139, 77.2090);
}

class AvailableLoadsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTrips;
  const AvailableLoadsScreen({super.key, this.onNavigateToTrips});

  @override
  State<AvailableLoadsScreen> createState() => _AvailableLoadsScreenState();
}

class _AvailableLoadsScreenState extends State<AvailableLoadsScreen> {
  final _fromController = TextEditingController(text: 'Sector 62, Noida (UP)');
  final _toController = TextEditingController();
  GoogleMapController? _mapController;

  List<PlaceSuggestion> _fromSuggestions = [];
  List<PlaceSuggestion> _toSuggestions = [];
  Timer? _debounceFrom;
  Timer? _debounceTo;

  LatLng? _fromLatLng;
  LatLng? _toLatLng;
  String? _fromName;
  String? _toName;

  RouteInfo? _currentRoute;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _proximityAlertShown = false;
  bool _showMap = false;

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
        _autoDetectDriverAndCheckProximity(vm);
      }
    });
  }

  Future<void> _autoDetectDriverAndCheckProximity(PartnerTripsViewModel tripsVM) async {
    try {
      final loc = await RoutingService.getCurrentLocation();
      if (loc != null && mounted) {
        if (_fromController.text.isEmpty || _fromController.text == 'Sector 62, Noida (UP)') {
          setState(() {
            _fromController.text = loc.city ?? loc.name;
            _fromLatLng = loc.latLng;
            _fromName = loc.city ?? loc.name;
          });
        }

        // Check for 0.5 - 12 km proximity loads
        if (!_proximityAlertShown && tripsVM.availableLoads.isNotEmpty) {
          for (final load in tripsVM.availableLoads) {
            final originCoords = RoutingService.getCoordinatesForCity(load.origin);
            if (originCoords != null) {
              final distMeters = Geolocator.distanceBetween(
                loc.latLng.latitude,
                loc.latLng.longitude,
                originCoords.latitude,
                originCoords.longitude,
              );
              final distKm = distMeters / 1000.0;
              if (distKm >= 0.5 && distKm <= 12.0) {
                _proximityAlertShown = true;
                _showProximityLoadPopup(load, distKm, tripsVM);
                break;
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  void _showProximityLoadPopup(AvailableLoad load, double distKm, PartnerTripsViewModel tripsVM) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandYellow.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar, color: AppColors.warning, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Load Near You!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    '${distKm.toStringAsFixed(1)} km away from your location',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${load.origin} ➔ ${load.destination}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Payout: ₹${load.offeredPriceInr.toInt()} • ${load.weightTons} T • ${load.cargoType}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ignore', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _selectRoute(load.origin, load.destination);
            },
            child: Text('View Corridor', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _onFromChanged(String q) {
    _debounceFrom?.cancel();
    _debounceFrom = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().isEmpty) {
        setState(() => _fromSuggestions = []);
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
    _debounceTo = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().isEmpty) {
        setState(() => _toSuggestions = []);
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

    final tempName = _fromName;
    _fromName = _toName;
    _toName = tempName;

    _updateFilterAndRoute();
  }

  void _selectRoute(String fromCity, String toCity) {
    setState(() {
      _fromController.text = fromCity;
      _toController.text = toCity;
      _fromName = fromCity;
      _toName = toCity;
      _fromLatLng = _resolveCoord(fromCity);
      _toLatLng = _resolveCoord(toCity);
    });
    _updateFilterAndRoute();
  }

  void _updateFilterAndRoute() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    final tripsVM = context.read<PartnerTripsViewModel>();

    if (from.isNotEmpty && to.isNotEmpty) {
      tripsVM.setSearchFilter('$from $to');
      _calculateAndShowRoute();
    } else if (from.isNotEmpty) {
      tripsVM.setSearchFilter(from);
    } else if (to.isNotEmpty) {
      tripsVM.setSearchFilter(to);
    } else {
      tripsVM.clearSearchFilter();
      setState(() {
        _currentRoute = null;
        _polylines = {};
        _markers = {};
      });
    }
  }

  Future<void> _calculateAndShowRoute() async {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    if (from.isEmpty || to.isEmpty) return;

    final start = _fromLatLng ?? _resolveCoord(from);
    final end = _toLatLng ?? _resolveCoord(to);

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
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      }
    } catch (_) {}
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
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.watch<PartnerTripsViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final isMetric = themeVM.isMetric;

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
      backgroundColor: const Color(0xFF0B0F19), // Deep Obsidian Dark Background matching screenshot
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP COCKPIT HEADER WITH ORIGINAL "R" LOGO
            _buildTopHeader(context),

            // Main Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandYellow,
                backgroundColor: const Color(0xFF1E293B),
                onRefresh: () => tripsVM.fetchAll(),
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
                    _buildHeroBanner(),
                    const SizedBox(height: 12),

                    // 3. DUAL STATUS STRIP (READY FOR LOADS + GPS LIVE TRACKING)
                    _buildStatusCardsRow(),
                    const SizedBox(height: 12),

                    // 4. SEARCH / ROUTE INTERCEPTION CARD
                    _buildSearchCard(isMetric),
                    const SizedBox(height: 16),

                    // OPTIONAL MAP VIEW IF TOGGLED
                    if (_showMap) ...[
                      _buildInteractiveMap(),
                      const SizedBox(height: 16),
                    ],

                    // 5. QUICK TOOLS 4-ACTION GRID
                    _buildQuickToolsGrid(context),
                    const SizedBox(height: 18),

                    // 6. DRIVE YOUR SUCCESS SECTION
                    _buildDriveYourSuccess(displayedLoads.length),
                    const SizedBox(height: 16),

                    // 7. REDO REWARDS BANNER
                    _buildRewardsBanner(context),
                    const SizedBox(height: 20),

                    // 8. FEATURED LOADS NEAR YOU HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Loads Near You',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'See All >',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandYellow,
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
                      _buildEmptyLoadsState()
                    else
                      ...displayedLoads.map((load) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLoadCard(load, currency, isMetric),
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
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF0B0F19),
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
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Move More Together',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Icons: Folded Map Toggle, Notification Bell, Partner Profile Avatar
          Row(
            children: [
              // Folded map toggle icon
              IconButton(
                icon: Icon(
                  _showMap ? Icons.view_agenda_outlined : Icons.map_outlined,
                  color: _showMap ? AppColors.brandYellow : Colors.white,
                  size: 22,
                ),
                tooltip: _showMap ? 'Hide Map' : 'Show Map',
                onPressed: () => setState(() => _showMap = !_showMap),
              ),

              // Notification bell with red badge
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                    Positioned(
                      top: 1,
                      right: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),

              const SizedBox(width: 4),

              // Partner Avatar with green active dot + "Partner" label
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PartnerSettingsScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.brandYellow, width: 1.5),
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Color(0xFF1E293B),
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0B0F19), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Partner',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
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

  // --- 2. HERO BANNER WITH CUSTOM COMMERCIAL TRUCK ---
  Widget _buildHeroBanner() {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Stack(
        children: [
          // Background Truck Image on right side
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 220,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/partner_hero_truck_banner.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(child: Icon(Icons.local_shipping, size: 48, color: AppColors.brandYellow)),
                    ),
                  ),
                  // Left-to-right fade gradient overlay to blend with dark banner
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF0F172A),
                          const Color(0xFF0F172A).withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Left Typography
          Positioned(
            left: 18,
            top: 18,
            bottom: 18,
            right: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'More Loads.',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Bigger Opportunities.',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandYellow,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find. Bid. Move. Grow with REDO.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Right Tagline Script: "Drivers / Partners / A Stronger Tomorrow"
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Drivers • Partners\nA Stronger Tomorrow',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: AppColors.brandYellow,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
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
  Widget _buildStatusCardsRow() {
    return Row(
      children: [
        // Left: Ready for Loads
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() => _isReadyForLoads = !_isReadyForLoads);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isReadyForLoads ? 'You are now visible to shippers' : 'Status set to Offline'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: _isReadyForLoads ? const Color(0xFF0C2419) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isReadyForLoads ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFF334155),
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
                          ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.6), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready for Loads',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _isReadyForLoads ? const Color(0xFF10B981) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isReadyForLoads ? 'You are visible to shippers' : 'Offline • Tap to activate',
                          style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isGpsSharingOn ? 'GPS Live Tracking Active' : 'GPS Sharing Paused'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me_outlined, size: 18, color: Color(0xFF38BDF8)),
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isGpsSharingOn ? 'Location sharing ON' : 'Location sharing OFF',
                          style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
  Widget _buildSearchCard(bool isMetric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
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
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E293B)),
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
                                'Pickup Location',
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                              TextField(
                                controller: _fromController,
                                onChanged: _onFromChanged,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'Sector 62, Noida (UP)',
                                  hintStyle: TextStyle(color: Color(0xFF475569), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () async {
                            final loc = await RoutingService.getCurrentLocation();
                            if (loc != null && mounted) {
                              setState(() {
                                _fromController.text = loc.city ?? loc.name;
                                _fromLatLng = loc.latLng;
                                _fromName = loc.city ?? loc.name;
                              });
                              _updateFilterAndRoute();
                            }
                          },
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
                          Container(width: 2, height: 4, color: const Color(0xFF334155)),
                          const SizedBox(height: 2),
                          Container(width: 2, height: 4, color: const Color(0xFF334155)),
                        ],
                      ),
                    ),
                  ),

                  // Destination Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E293B)),
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
                                'To City / Destination',
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                              TextField(
                                controller: _toController,
                                onChanged: _onToChanged,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'Search city, state or pincode',
                                  hintStyle: TextStyle(color: Color(0xFF475569), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_toController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _toController.clear();
                              _toLatLng = null;
                              _toName = null;
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
                      color: const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF334155)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.swap_vert, color: AppColors.brandYellow, size: 20),
                  ),
                ),
              ),
            ],
          ),

          // Autocomplete Dropdown suggestions (if user is typing)
          if (_fromSuggestions.isNotEmpty || _toSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_fromSuggestions.isNotEmpty)
                    ..._fromSuggestions.map((s) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.place, color: Color(0xFF10B981), size: 16),
                          title: Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          subtitle: Text(s.description, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                          onTap: () {
                            setState(() {
                              _fromController.text = s.name;
                              _fromLatLng = s.latLng;
                              _fromName = s.name;
                              _fromSuggestions = [];
                            });
                            _updateFilterAndRoute();
                          },
                        )),
                  if (_toSuggestions.isNotEmpty)
                    ..._toSuggestions.map((s) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.place, color: Color(0xFFEF4444), size: 16),
                          title: Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          subtitle: Text(s.description, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                          onTap: () {
                            setState(() {
                              _toController.text = s.name;
                              _toLatLng = s.latLng;
                              _toName = s.name;
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
                _buildRouteChip('Delhi ⇄ Mumbai', 'Delhi', 'Mumbai'),
                const SizedBox(width: 8),
                _buildRouteChip('Mumbai ⇄ Pune', 'Mumbai', 'Pune'),
                const SizedBox(width: 8),
                _buildRouteChip('Bengaluru ⇄ Chennai', 'Bengaluru', 'Chennai'),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _selectRoute('Kolkata', 'Patna'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 14, color: AppColors.brandYellow),
                        const SizedBox(width: 4),
                        Text('More', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Category Filter Tabs (All Loads, Instant, Scheduled, Best Match)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryTab('All Loads', Icons.local_shipping, isAll: true),
                const SizedBox(width: 8),
                _buildCategoryTab('Instant', Icons.bolt),
                const SizedBox(width: 8),
                _buildCategoryTab('Scheduled', Icons.calendar_today),
                const SizedBox(width: 8),
                _buildCategoryTab('Best Match', Icons.star),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tonnage Filter Row
          Row(
            children: [
              Text(
                'Tonnage:',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 10),
              _buildTonnagePill('All'),
              const SizedBox(width: 6),
              _buildTonnagePill('< 3T'),
              const SizedBox(width: 6),
              _buildTonnagePill('3 - 10T'),
              const SizedBox(width: 6),
              _buildTonnagePill('10T+'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Showing loads for ${_fromController.text} → ${_toController.text.isNotEmpty ? _toController.text : "All Destinations"}'),
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

  Widget _buildRouteChip(String label, String from, String to) {
    final isSel = _fromController.text.toLowerCase().contains(from.toLowerCase()) &&
        _toController.text.toLowerCase().contains(to.toLowerCase());

    return InkWell(
      onTap: () => _selectRoute(from, to),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.brandYellow.withValues(alpha: 0.15) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? AppColors.brandYellow : const Color(0xFF334155)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSel ? AppColors.brandYellow : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String title, IconData icon, {bool isAll = false}) {
    final isSel = _selectedCategory == title;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = title),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.brandYellow : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? AppColors.brandYellow : const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSel ? AppColors.slateDark : Colors.white),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSel ? AppColors.slateDark : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTonnagePill(String tonnage) {
    final isSel = _selectedTonnage == tonnage;
    return InkWell(
      onTap: () => setState(() => _selectedTonnage = tonnage),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF334155) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? AppColors.brandYellow : const Color(0xFF1E293B)),
        ),
        child: Text(
          tonnage,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  // --- INTERACTIVE MAP PREVIEW ---
  Widget _buildInteractiveMap() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _fromLatLng ?? const LatLng(28.6139, 77.2090),
                zoom: 5.5,
              ),
              polylines: _polylines,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (c) => _mapController = c,
            ),
            if (_currentRoute != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_currentRoute!.distanceText} • ETA ${_currentRoute!.durationText}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandYellow),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- 5. QUICK TOOLS 4-ACTION GRID ---
  Widget _buildQuickToolsGrid(BuildContext context) {
    return Row(
      children: [
        _buildToolCard(
          icon: Icons.notifications_active_outlined,
          hasDot: true,
          title: 'Load Alerts',
          subtitle: 'Get notified first',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Instant Load Proximity Alerts Active for your truck.')),
            );
          },
        ),
        const SizedBox(width: 8),
        _buildToolCard(
          icon: Icons.alt_route_outlined,
          title: 'Saved Routes',
          subtitle: 'Quick access',
          onTap: () => _selectRoute('Delhi', 'Mumbai'),
        ),
        const SizedBox(width: 8),
        _buildToolCard(
          icon: Icons.gavel_outlined,
          title: 'My Bids',
          subtitle: 'Track & manage',
          onTap: () => widget.onNavigateToTrips?.call(),
        ),
        const SizedBox(width: 8),
        _buildToolCard(
          icon: Icons.local_gas_station_outlined,
          title: 'Fuel Prices',
          subtitle: 'Plan smarter',
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                title: Text('Live Diesel Prices (NCR)', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white)),
                content: Text(
                  'Delhi: ₹87.62/L\nNoida: ₹87.96/L\nMumbai: ₹92.15/L\nJaipur: ₹90.36/L\n\nDirect fuel fleet card discounts apply automatically.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: Colors.white70),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    bool hasDot = false,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Icon(icon, size: 22, color: Colors.white),
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
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF94A3B8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 6. DRIVE YOUR SUCCESS SECTION ---
  Widget _buildDriveYourSuccess(int loadCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
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
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Insights to help you earn more',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Text(
                'View All >',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandYellow),
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
                value: '${max(12, loadCount)}',
                label: 'New Loads Today',
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                icon: Icons.currency_rupee,
                iconColor: const Color(0xFF38BDF8),
                value: '₹ 48,500',
                label: 'Avg. Rate (per trip)',
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                icon: Icons.bar_chart,
                iconColor: const Color(0xFFA855F7),
                value: '95%',
                label: 'On-time Loadings',
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                icon: Icons.star,
                iconColor: const Color(0xFFF59E0B),
                value: '4.8',
                label: 'Partner Rating',
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
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
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
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF94A3B8)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- 7. REDO REWARDS BANNER ---
  Widget _buildRewardsBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(16),
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
                  'Complete more trips • Earn rewards • Unlock benefits',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF451A03)),
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
                  backgroundColor: const Color(0xFF1E293B),
                  title: Text('REDO Partner Rewards', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white)),
                  content: Text(
                    'Level 1: Silver Tier (5 trips) - ₹1,000 Diesel Voucher\nLevel 2: Gold Tier (15 trips) - Priority Matching + Zero Commission\nLevel 3: Platinum Club (30 trips) - Guaranteed Return Backhaul + Health Insurance',
                    style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: Colors.white70),
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

  // --- 8. FEATURED LOAD CARD (Matching Uploaded Screenshot) ---
  Widget _buildLoadCard(AvailableLoad load, NumberFormat currency, bool isMetric) {
    final weightStr = UnitFormatter.formatWeightTons(load.weightTons, isMetric: isMetric);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
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
                    color: Colors.white,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '2h ago',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B),
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
                  const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    load.cargoType,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.scale_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    weightStr,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    'Today - Tomorrow',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF1E293B)),
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
                    style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    currency.format(load.offeredPriceInr),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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
                            counterpartyName: load.smeName.isNotEmpty ? load.smeName : 'Shipper',
                            counterpartyRole: 'Verified Shipper',
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
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
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
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Icon(Icons.map_outlined, size: 18, color: AppColors.brandYellow),
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
                    onPressed: () => _showAcceptLoadModal(load, currency),
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

  void _showAcceptLoadModal(AvailableLoad load, NumberFormat currency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
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
                      color: const Color(0xFF334155),
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
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Verified Shipper', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trip_origin, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pickup: ${load.origin}${load.pickupAddress != null ? " (${load.pickupAddress})" : ""}',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Drop: ${load.destination}${load.dropAddress != null ? " (${load.dropAddress})" : ""}',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Guaranteed Net Payout', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                    Text(
                      currency.format(load.offeredPriceInr),
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.brandYellow),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
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
                            final bookingId = await context.read<PartnerTripsViewModel>().acceptLoad(load);
                            if (!mounted) return;
                            setSheetState(() => accepting = false);
                            Navigator.pop(ctx);

                            if (bookingId != null) {
                              // Online continual learning feedback trigger
                              SupabaseService.sendRecommendationFeedback(
                                cargoId: load.cargoId,
                                action: 'accept_load',
                                corridorKey: '${load.origin.toLowerCase()}_${load.destination.toLowerCase()}',
                              );
                              CorridorMLService().recordInteraction(
                                '${load.origin.toLowerCase()}_${load.destination.toLowerCase()}',
                                'accept_load',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Load Locked! Booking ID: $bookingId')),
                              );
                              widget.onNavigateToTrips?.call();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to accept load. Please try again.')),
                              );
                            }
                          },
                    child: accepting
                        ? const CircularProgressIndicator(color: AppColors.slateDark)
                        : Text('Lock & Accept Load', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyLoadsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            'No loads matching this criteria',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Try clearing filters or checking other high-demand corridors.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
