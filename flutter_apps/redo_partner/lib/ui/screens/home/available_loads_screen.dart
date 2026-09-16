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
import '../../../l10n/app_localizations.dart';

const _cityLatLng = <String, LatLng>{
  'Mumbai': LatLng(19.0760, 72.8777),
  'Delhi NCR': LatLng(28.6139, 77.2090),
  'Delhi': LatLng(28.6139, 77.2090),
  'Pune': LatLng(18.5204, 73.8567),
  'Jaipur': LatLng(26.9124, 75.7873),
  'Surat': LatLng(21.1702, 72.8311),
  'Ahmedabad': LatLng(23.0225, 72.5714),
  'Bengaluru': LatLng(12.9716, 77.5946),
  'Bangalore': LatLng(12.9716, 77.5946),
  'Hyderabad': LatLng(17.3850, 78.4867),
  'Chennai': LatLng(13.0827, 80.2707),
  'Kolkata': LatLng(22.5726, 88.3639),
  'Lucknow': LatLng(26.8467, 80.9462),
  'Kanpur': LatLng(26.4499, 80.3319),
  'Indore': LatLng(22.7196, 75.8577),
  'Nagpur': LatLng(21.1458, 79.0882),
  'Bhopal': LatLng(23.2599, 77.4126),
  'Patna': LatLng(25.5941, 85.1376),
  'Agra': LatLng(27.1767, 78.0081),
  'Varanasi': LatLng(25.3176, 82.9739),
  'Chandigarh': LatLng(30.7333, 76.7794),
  'Ludhiana': LatLng(30.9010, 75.8573),
};

LatLng _posFor(String city) {
  final resolved = RoutingService.getCoordinatesForCity(city);
  if (resolved != null) return resolved;
  for (final entry in _cityLatLng.entries) {
    if (city.toLowerCase().contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  return const LatLng(25.5941, 85.1376);
}

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
  bool _searchingFrom = false;
  bool _searchingTo = false;
  Timer? _debounceFrom;
  Timer? _debounceTo;

  LatLng? _fromLatLng;
  LatLng? _toLatLng;
  String? _fromName;
  String? _toName;

  RouteInfo? _currentRoute;
  bool _calculatingRoute = false;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _proximityAlertShown = false;
  bool _showMap = false;

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
        if (_fromController.text.isEmpty) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
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
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
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
                color: isDark ? AppColors.darkCanvas : AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(load.smeName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(
                        '₹${load.offeredPriceInr.round()}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(load.origin, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 12, color: AppColors.inkMuted),
                      ),
                      const Icon(Icons.location_on, size: 10, color: AppColors.danger),
                      const SizedBox(width: 4),
                      Text(load.destination, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${load.cargoType} • ${load.weightTons} T',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Driver within 12km priority dispatch. Tap accept to lock this load.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ignore', style: GoogleFonts.inter(color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await tripsVM.acceptLoad(load);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Load accepted! Assigned to your trip.'),
                    backgroundColor: AppColors.success,
                  ),
                );
                widget.onNavigateToTrips?.call();
              }
            },
            child: Text('Accept Load', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _debounceFrom?.cancel();
    _debounceTo?.cancel();
    super.dispose();
  }

  void _onFromChanged(String value) {
    _debounceFrom?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _fromSuggestions = [];
        _searchingFrom = false;
      });
      return;
    }
    setState(() => _searchingFrom = true);
    _debounceFrom = Timer(const Duration(milliseconds: 350), () async {
      final res = await RoutingService.searchPlaces(value.trim());
      if (mounted) {
        setState(() {
          _fromSuggestions = res;
          _searchingFrom = false;
        });
      }
    });
  }

  void _onToChanged(String value) {
    _debounceTo?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _toSuggestions = [];
        _searchingTo = false;
      });
      return;
    }
    setState(() => _searchingTo = true);
    _debounceTo = Timer(const Duration(milliseconds: 350), () async {
      final res = await RoutingService.searchPlaces(value.trim());
      if (mounted) {
        setState(() {
          _toSuggestions = res;
          _searchingTo = false;
        });
      }
    });
  }

  void _selectFromPlace(PlaceSuggestion suggestion) {
    final chosen = suggestion.city ?? suggestion.name;
    _fromController.text = chosen;
    setState(() {
      _fromLatLng = suggestion.latLng;
      _fromName = chosen;
      _fromSuggestions = [];
    });
    if (_fromLatLng != null && _toLatLng != null) {
      _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, _fromName ?? '', _toName ?? '');
    }
    context.read<PartnerTripsViewModel>().setRouteSearch(
      from: _fromController.text.trim(),
      to: _toController.text.trim(),
    );
  }

  void _selectToPlace(PlaceSuggestion suggestion) {
    final chosen = suggestion.city ?? suggestion.name;
    _toController.text = chosen;
    setState(() {
      _toLatLng = suggestion.latLng;
      _toName = chosen;
      _toSuggestions = [];
    });
    if (_fromLatLng != null && _toLatLng != null) {
      _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, _fromName ?? '', _toName ?? '');
    }
    context.read<PartnerTripsViewModel>().setRouteSearch(
      from: _fromController.text.trim(),
      to: _toController.text.trim(),
    );
  }

  Future<void> _calculateAndDrawRoute(LatLng origin, LatLng dest, String fromCity, String toCity) async {
    setState(() => _calculatingRoute = true);
    final route = await RoutingService.getDrivingRoute(origin, dest);
    if (!mounted) return;

    if (route != null) {
      final polyline = Polyline(
        polylineId: const PolylineId('active_search_route'),
        points: route.points,
        color: AppColors.brandYellow,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );

      final originMarker = Marker(
        markerId: const MarkerId('route_origin'),
        position: origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup: $fromCity'),
      );

      final destMarker = Marker(
        markerId: const MarkerId('route_dest'),
        position: dest,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Drop: $toCity'),
      );

      setState(() {
        _currentRoute = route;
        _polylines = {polyline};
        _markers = {originMarker, destMarker};
        _calculatingRoute = false;
        _showMap = true;
      });

      if (_mapController != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(min(origin.latitude, dest.latitude) - 0.5, min(origin.longitude, dest.longitude) - 0.5),
          northeast: LatLng(max(origin.latitude, dest.latitude) + 0.5, max(origin.longitude, dest.longitude) + 0.5),
        );
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } else {
      setState(() => _calculatingRoute = false);
    }
  }

  void _selectLoadRoute(AvailableLoad load) {
    final originPos = _posFor(load.origin);
    final destPos = _posFor(load.destination);

    _fromController.text = load.origin;
    _toController.text = load.destination;
    _fromName = load.origin;
    _toName = load.destination;
    _fromLatLng = originPos;
    _toLatLng = destPos;

    _calculateAndDrawRoute(originPos, destPos, load.origin, load.destination);
  }

  void _clearRoute() {
    setState(() {
      _fromController.clear();
      _toController.clear();
      _fromLatLng = null;
      _toLatLng = null;
      _fromName = null;
      _toName = null;
      _currentRoute = null;
      _polylines.clear();
      _markers.clear();
      _fromSuggestions.clear();
      _toSuggestions.clear();
    });
    context.read<PartnerTripsViewModel>().clearFilters();
  }

  void _swapLocations() {
    final tempText = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = tempText;

    final tempName = _fromName;
    _fromName = _toName;
    _toName = tempName;

    final tempLatLng = _fromLatLng;
    _fromLatLng = _toLatLng;
    _toLatLng = tempLatLng;

    if (_fromLatLng != null && _toLatLng != null) {
      _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, _fromName ?? '', _toName ?? '');
    }
    context.read<PartnerTripsViewModel>().setRouteSearch(
      from: _fromController.text.trim(),
      to: _toController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.watch<PartnerTripsViewModel>();
    final loads = tripsVM.availableLoads;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Set<Marker> displayMarkers = _markers.isNotEmpty
        ? _markers
        : {
            for (final l in loads)
              Marker(
                markerId: MarkerId('load-${l.cargoId}'),
                position: _posFor(l.origin),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                infoWindow: InfoWindow(
                  title: '${l.origin} → ${l.destination}',
                  snippet: '${l.weightTons} T • ₹${l.offeredPriceInr.round()}',
                  onTap: () => _selectLoadRoute(l),
                ),
              ),
          };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'REDO',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slateDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.availableLoads ?? 'Available Return Loads',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'AI ML Matched • Live Corridors',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Toggle Map / Feed View
          IconButton(
            icon: Icon(_showMap ? Icons.view_list_rounded : Icons.map_outlined),
            tooltip: _showMap ? 'Show List Feed' : 'Show Map View',
            color: _showMap ? AppColors.brandYellow : (isDark ? AppColors.darkInk : AppColors.slateDark),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          const NotificationsBell(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PartnerSettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => tripsVM.fetchAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Cockpit Bar: Driver & Live GPS status
          _buildDriverCockpitBar(isDark),

          // Search Card (From / To with Auto-suggest & Quick Corridors)
          _buildSearchCard(isDark, l10n),

          // Interactive Map (collapsible)
          if (_showMap)
            _buildInteractiveMap(displayMarkers, isDark),

          // Live-location "Recommended near you" Strip (AI Corridor Demand)
          if (tripsVM.recommendedCorridors.isNotEmpty)
            _RecommendedCorridorsStrip(tripsVM: tripsVM),

          // Filters Row (Categories: All, Instant, Scheduled, Best Match ML + Tonnage)
          _buildFilterTabsRow(tripsVM, isDark),

          // Instant Dispatch Alert Banner (if any)
          if (tripsVM.instantAlertLoad != null)
            InstantLoadAlertBanner(
              load: tripsVM.instantAlertLoad!,
              secondsRemaining: tripsVM.instantSecondsLeft,
              onAccept: () async {
                final alertLoad = tripsVM.instantAlertLoad;
                if (alertLoad != null) {
                  tripsVM.dismissInstantAlert(declined: false);
                  await tripsVM.acceptLoad(alertLoad);
                }
              },
              onDecline: () => tripsVM.dismissInstantAlert(declined: true),
            ),

          // Main Loads List
          Expanded(
            child: _LoadsBody(
              tripsVM: tripsVM,
              loads: loads,
              onNavigateToTrips: widget.onNavigateToTrips,
              onSelectRoute: _selectLoadRoute,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCockpitBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.darkCanvas : const Color(0xFFF1F5F9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ready for Loads',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_fixed, size: 11, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 4),
                    Text(
                      'GPS Live Tracking',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Consumer<ThemeViewModel>(
            builder: (context, themeVM, _) {
              return Text(
                themeVM.isMetric ? 'Metric (km/T)' : 'Imperial (mi/lbs)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Icon(Icons.radio_button_checked, size: 15, color: AppColors.success),
                  Container(width: 2, height: 26, color: isDark ? AppColors.darkBorder : AppColors.border),
                  const Icon(Icons.location_on, size: 15, color: AppColors.danger),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _fromController,
                        onChanged: _onFromChanged,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: l10n?.fromCity ?? 'Pickup Hub (e.g. Delhi, Mumbai)…',
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          suffixIcon: _searchingFrom
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : _fromController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _fromController.clear();
                                        setState(() {
                                          _fromLatLng = null;
                                          _fromName = null;
                                          _fromSuggestions = [];
                                        });
                                        context.read<PartnerTripsViewModel>().setRouteSearch(from: '', to: _toController.text.trim());
                                      },
                                    )
                                  : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _toController,
                        onChanged: _onToChanged,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: l10n?.toCity ?? 'Destination / Return City…',
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          suffixIcon: _searchingTo
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : _toController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _toController.clear();
                                        setState(() {
                                          _toLatLng = null;
                                          _toName = null;
                                          _toSuggestions = [];
                                        });
                                        context.read<PartnerTripsViewModel>().setRouteSearch(from: _fromController.text.trim(), to: '');
                                      },
                                    )
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
                icon: const Icon(Icons.swap_vert, size: 20, color: AppColors.brandYellowDark),
                tooltip: 'Swap Route',
                onPressed: _swapLocations,
              ),
            ],
          ),

          // Suggestions list if searching
          if (_fromSuggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _fromSuggestions.length,
                itemBuilder: (ctx, i) {
                  final s = _fromSuggestions[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_city, size: 16, color: AppColors.brandYellowDark),
                    title: Text(s.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: Text(s.description, style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted)),
                    onTap: () => _selectFromPlace(s),
                  );
                },
              ),
            ),
          ],
          if (_toSuggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _toSuggestions.length,
                itemBuilder: (ctx, i) {
                  final s = _toSuggestions[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, size: 16, color: AppColors.danger),
                    title: Text(s.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: Text(s.description, style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted)),
                    onTap: () => _selectToPlace(s),
                  );
                },
              ),
            ),
          ],

          // Quick Corridor Chips
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickCorridorChip('Delhi ⇄ Mumbai', 'Delhi', 'Mumbai'),
                _buildQuickCorridorChip('Mumbai ⇄ Pune', 'Mumbai', 'Pune'),
                _buildQuickCorridorChip('Bengaluru ⇄ Chennai', 'Bengaluru', 'Chennai'),
                _buildQuickCorridorChip('Delhi ⇄ Kolkata', 'Delhi', 'Kolkata'),
                _buildQuickCorridorChip('Hyderabad ⇄ Vijayawada', 'Hyderabad', 'Vijayawada'),
                if (_fromController.text.isNotEmpty || _toController.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearRoute,
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.close, size: 12, color: AppColors.danger),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.danger),
                          ),
                        ],
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

  Widget _buildQuickCorridorChip(String label, String from, String to) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = (_fromController.text.toLowerCase().contains(from.toLowerCase()) &&
        _toController.text.toLowerCase().contains(to.toLowerCase()));

    return GestureDetector(
      onTap: () {
        _fromController.text = from;
        _toController.text = to;
        _fromName = from;
        _toName = to;
        _fromLatLng = _posFor(from);
        _toLatLng = _posFor(to);
        _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, from, to);
        context.read<PartnerTripsViewModel>().setRouteSearch(from: from, to: to);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandYellow
              : (isDark ? AppColors.darkCanvas : AppColors.canvas),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.brandYellowDark : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.slateDark : (isDark ? AppColors.darkInk : AppColors.ink),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveMap(Set<Marker> displayMarkers, bool isDark) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629),
              zoom: 4.8,
            ),
            onMapCreated: (ctrl) => _mapController = ctrl,
            polylines: _polylines,
            markers: displayMarkers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          if (_calculatingRoute)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.brandYellow),
              ),
            ),
          if (_currentRoute != null)
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.route, size: 14, color: AppColors.brandYellowDark),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentRoute!.distanceKm.round()} km • ${_currentRoute!.durationText}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 12,
            top: 12,
            child: FloatingActionButton.small(
              heroTag: 'recenter_map',
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              foregroundColor: AppColors.slateDark,
              onPressed: () {
                if (_fromLatLng != null && _toLatLng != null && _mapController != null) {
                  final bounds = LatLngBounds(
                    southwest: LatLng(
                      min(_fromLatLng!.latitude, _toLatLng!.latitude) - 0.5,
                      min(_fromLatLng!.longitude, _toLatLng!.longitude) - 0.5,
                    ),
                    northeast: LatLng(
                      max(_fromLatLng!.latitude, _toLatLng!.latitude) + 0.5,
                      max(_fromLatLng!.longitude, _toLatLng!.longitude) + 0.5,
                    ),
                  );
                  _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                }
              },
              child: const Icon(Icons.my_location, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabsRow(PartnerTripsViewModel tripsVM, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Row(
            children: [
              _buildCategoryTab(tripsVM, 'all', 'All Loads', Icons.local_shipping_outlined, isDark),
              const SizedBox(width: 6),
              _buildCategoryTab(tripsVM, 'instant', '⚡ Instant', Icons.bolt, isDark),
              const SizedBox(width: 6),
              _buildCategoryTab(tripsVM, 'scheduled', '📅 Scheduled', Icons.calendar_today_outlined, isDark),
              const SizedBox(width: 6),
              _buildCategoryTab(tripsVM, 'best_match', '★ Best Match', Icons.auto_awesome, isDark),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Tonnage:',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkMuted),
              ),
              const SizedBox(width: 8),
              _buildTonnageChip(tripsVM, 'all', 'All', isDark),
              const SizedBox(width: 4),
              _buildTonnageChip(tripsVM, 'mini', '< 3T', isDark),
              const SizedBox(width: 4),
              _buildTonnageChip(tripsVM, 'medium', '3 - 10T', isDark),
              const SizedBox(width: 4),
              _buildTonnageChip(tripsVM, 'heavy', '10T+', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(PartnerTripsViewModel vm, String key, String label, IconData icon, bool isDark) {
    final isSelected = vm.categoryFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setCategoryFilter(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandYellow
                : (isDark ? AppColors.darkCanvas : AppColors.canvas),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.brandYellowDark : (isDark ? AppColors.darkBorder : AppColors.border),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? AppColors.slateDark : AppColors.inkMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.slateDark : (isDark ? AppColors.darkInk : AppColors.ink),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTonnageChip(PartnerTripsViewModel vm, String key, String label, bool isDark) {
    final isSelected = vm.tonnageFilter == key;
    return GestureDetector(
      onTap: () => vm.setTonnageFilter(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.inkMuted : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? (isDark ? AppColors.darkInk : AppColors.slateDark) : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Horizontal strip of "which city should I head toward" corridor
/// suggestions, built from real open-cargo demand near the driver's live
/// location (backend: GET /recommendations/nearby/:truck_id). Tapping a
/// corridor filters the loads list to it.
class _RecommendedCorridorsStrip extends StatelessWidget {
  final PartnerTripsViewModel tripsVM;
  const _RecommendedCorridorsStrip({required this.tripsVM});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corridors = tripsVM.recommendedCorridors;
    final lastTrip = tripsVM.nearbyRecommendations?['last_trip'] as Map?;

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF3B82F6)),
                const SizedBox(width: 6),
                Text(
                  'Recommended Near You',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkInk : AppColors.slateDark),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AI Demand',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                  ),
                ),
                if (tripsVM.loadingRecommendations) ...[
                  const SizedBox(width: 8),
                  const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.6)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: corridors.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = corridors[i];
                final destination = c['destination'] as String? ?? '';
                final count = c['open_load_count'] as int? ?? 0;
                final avgPrice = c['avg_estimated_price_inr'] as int? ?? 0;
                final distKm = c['distance_from_here_km'];
                final isBackhaul = lastTrip != null &&
                    (lastTrip['origin'] as String? ?? '').toLowerCase() == destination.toLowerCase();

                final isSelected = tripsVM.searchFilter.toLowerCase().contains(destination.toLowerCase());

                return GestureDetector(
                  onTap: () => tripsVM.setSearchFilter(destination),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
                          : isBackhaul
                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                              : (isDark ? AppColors.darkCard : AppColors.canvas),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : isBackhaul
                                ? AppColors.success
                                : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: isSelected || isBackhaul ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(destination, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800)),
                            if (isBackhaul) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.replay_circle_filled, size: 14, color: AppColors.success),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '$count loads • ~₹$avgPrice avg',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
                            ),
                            if (distKm != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '• ${distKm}km',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF3B82F6)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadsBody extends StatelessWidget {
  final PartnerTripsViewModel tripsVM;
  final List<AvailableLoad> loads;
  final VoidCallback? onNavigateToTrips;
  final Function(AvailableLoad) onSelectRoute;

  const _LoadsBody({
    required this.tripsVM,
    required this.loads,
    this.onNavigateToTrips,
    required this.onSelectRoute,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return (tripsVM.isLoading && loads.isEmpty)
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.brandYellow),
            ),
          )
        : loads.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore_off, size: 48, color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted),
                      const SizedBox(height: 12),
                      Text(
                        l10n?.noLoadsFound ?? 'No return loads found on this filter.',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? AppColors.darkInk : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try clearing your search filter or selecting a major freight corridor above.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandYellow,
                          foregroundColor: AppColors.slateDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: Text(
                          l10n?.clear ?? 'Show All Return Loads',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                        ),
                        onPressed: () {
                          tripsVM.clearFilters();
                          tripsVM.fetchAll();
                        },
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: loads.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final load = loads[index];
                  return _LoadCard(
                    load: load,
                    tripsVM: tripsVM,
                    onNavigateToTrips: onNavigateToTrips,
                    onSelectRoute: onSelectRoute,
                  );
                },
              );
  }
}

class _LoadCard extends StatefulWidget {
  final AvailableLoad load;
  final PartnerTripsViewModel tripsVM;
  final VoidCallback? onNavigateToTrips;
  final Function(AvailableLoad) onSelectRoute;

  const _LoadCard({
    required this.load,
    required this.tripsVM,
    this.onNavigateToTrips,
    required this.onSelectRoute,
  });

  @override
  State<_LoadCard> createState() => _LoadCardState();
}

class _LoadCardState extends State<_LoadCard> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final load = widget.load;
    final tripsVM = widget.tripsVM;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMetric = context.watch<ThemeViewModel>().isMetric;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Shipper name & Guaranteed Payout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                      child: Text(
                        load.smeName.isNotEmpty ? load.smeName[0].toUpperCase() : 'S',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.brandYellowDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(load.smeName, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: AppColors.success),
                          ],
                        ),
                        Text(
                          load.pickupWindow,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(load.offeredPriceInr),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'Guaranteed Payout',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Route Corridor Visual: Origin ── 🛣️ Distance ──> Destination
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCanvas : AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      load.origin,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alt_route, size: 12, color: AppColors.inkMuted),
                        const SizedBox(width: 4),
                        Text(
                          UnitFormatter.formatDistance(load.distanceKm, isMetric: isMetric),
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on, size: 12, color: AppColors.danger),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      load.destination,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Intelligence Badges Row (ML Score, Corridor Match, Weight, Cargo)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Real ML Match Score
                if (load.hasRealMatchScore)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF3B82F6), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          '${load.matchScore}% ML Match',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),

                // En-Route Corridor Interception Badge
                () {
                  final mlMatch = tripsVM.getMatchResult(load.cargoId);
                  if (mlMatch != null && mlMatch.isMatch) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.success, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mlMatch.matchType == EnRouteType.direct
                                ? Icons.bolt
                                : (mlMatch.matchType == EnRouteType.returnBackhaul
                                    ? Icons.sync_alt
                                    : Icons.alt_route),
                            size: 12,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mlMatch.badgeText,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }(),

                // Cargo Spec & Weight
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.canvas,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${load.cargoType} • ${UnitFormatter.formatWeightTons(load.weightTons, isMetric: isMetric)}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Action Bar: Chat, Route on Map, Accept Load
            Row(
              children: [
                // Chat with Shipper
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 15, color: Color(0xFF2563EB)),
                  label: Text('Chat', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectChatScreen(
                          bookingId: 'PRE-${load.cargoId}',
                          counterpartyName: load.smeName,
                          counterpartyRole: 'Shipper',
                          counterpartyPhone: '+91 98201 22334',
                          truckReg: 'Commercial Fleet',
                          origin: load.origin,
                          destination: load.destination,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 6),

                // View Route on Map
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 15, color: AppColors.inkMuted),
                  label: Text('Route', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkMuted)),
                  onPressed: () {
                    tripsVM.recordLoadView(load);
                    widget.onSelectRoute(load);
                  },
                ),

                const SizedBox(width: 8),

                // Accept Load Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: AppColors.slateDark,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: _isAccepting
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isAccepting = true);
                            final bookingId = await tripsVM.acceptLoad(load);
                            if (!mounted) return;
                            setState(() => _isAccepting = false);
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
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                                  title: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                                      const SizedBox(width: 8),
                                      Text('Booking Confirmed!', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Booking ID: $bookingId\nTrip locked for ${load.origin} → ${load.destination}.\nPayout: ${currency.format(load.offeredPriceInr)}',
                                        style: GoogleFonts.inter(fontSize: 13, height: 1.4),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'The shipper has been notified. You can now start live tracking or view the trip in your Active Trips tab.',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => navigator.pop(),
                                      child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.brandYellow,
                                        foregroundColor: AppColors.slateDark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        navigator.pop();
                                        widget.onNavigateToTrips?.call();
                                      },
                                      child: Text('Go to Trips', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to accept load. Please try again.'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          },
                    child: _isAccepting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slateDark),
                          )
                        : Text(
                            'Accept Load',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
