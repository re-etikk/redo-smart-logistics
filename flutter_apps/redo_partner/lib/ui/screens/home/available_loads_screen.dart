import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/routing_service.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../misc/notifications_screen.dart';
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
  for (final entry in _cityLatLng.entries) {
    if (city.toLowerCase().contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  return const LatLng(23.5, 76.0);
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<PartnerTripsViewModel>().fetchAll();
      }
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _debounceFrom?.cancel();
    _debounceTo?.cancel();
    super.dispose();
  }

  void _onFromChanged(String val) {
    _debounceFrom?.cancel();
    if (val.trim().length < 2) {
      setState(() => _fromSuggestions = []);
      return;
    }
    _debounceFrom = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _searchingFrom = true);
      final results = await RoutingService.searchPlaces(val);
      if (mounted) {
        setState(() {
          _fromSuggestions = results;
          _searchingFrom = false;
        });
      }
    });
  }

  void _onToChanged(String val) {
    _debounceTo?.cancel();
    if (val.trim().length < 2) {
      setState(() => _toSuggestions = []);
      return;
    }
    _debounceTo = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _searchingTo = true);
      final results = await RoutingService.searchPlaces(val);
      if (mounted) {
        setState(() {
          _toSuggestions = results;
          _searchingTo = false;
        });
      }
    });
  }

  void _selectFromPlace(PlaceSuggestion place, PartnerTripsViewModel tripsVM) {
    setState(() {
      _fromSuggestions = [];
      _fromController.text = place.name;
      _fromName = place.name;
      _fromLatLng = place.latLng;
    });
    tripsVM.setRouteSearch(from: place.name, to: _toController.text.trim());

    if (_toLatLng != null) {
      _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, _fromName!, _toName!);
    } else {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: place.latLng, zoom: 11)),
      );
      _updateSingleMarker(place.latLng, place.name, isOrigin: true);
    }
  }

  void _selectToPlace(PlaceSuggestion place, PartnerTripsViewModel tripsVM) {
    setState(() {
      _toSuggestions = [];
      _toController.text = place.name;
      _toName = place.name;
      _toLatLng = place.latLng;
    });
    tripsVM.setRouteSearch(from: _fromController.text.trim(), to: place.name);

    if (_fromLatLng != null) {
      _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, _fromName!, _toName!);
    } else {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: place.latLng, zoom: 11)),
      );
      _updateSingleMarker(place.latLng, place.name, isOrigin: false);
    }
  }

  void _updateSingleMarker(LatLng pos, String name, {required bool isOrigin}) {
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(isOrigin ? 'origin' : 'dest'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isOrigin ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(title: '${isOrigin ? "Pickup" : "Drop"}: $name'),
        ),
      };
    });
  }

  Future<void> _calculateAndDrawRoute(
    LatLng origin,
    LatLng destination,
    String originName,
    String destName,
  ) async {
    setState(() => _calculatingRoute = true);

    final route = await RoutingService.getDrivingRoute(origin, destination);
    if (!mounted) return;

    if (route != null && route.points.isNotEmpty) {
      final polyline = Polyline(
        polylineId: const PolylineId('active_driving_route'),
        points: route.points,
        color: const Color(0xFF0F172A),
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );

      final originMarker = Marker(
        markerId: const MarkerId('route_origin'),
        position: origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup: $originName'),
      );

      final destMarker = Marker(
        markerId: const MarkerId('route_dest'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Drop: $destName'),
      );

      setState(() {
        _currentRoute = route;
        _polylines = {polyline};
        _markers = {originMarker, destMarker};
        _calculatingRoute = false;
      });

      // Fit bounds
      final southWest = LatLng(
        min(origin.latitude, destination.latitude),
        min(origin.longitude, destination.longitude),
      );
      final northEast = LatLng(
        max(origin.latitude, destination.latitude),
        max(origin.longitude, destination.longitude),
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: southWest, northeast: northEast),
          60,
        ),
      );
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

    // Default markers for all loads if no specific route active
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
        title: Text(
          l10n?.availableLoads ?? 'Available Return Loads',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          const NotificationsBell(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => tripsVM.fetchAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Dual Location Search (Pickup + Drop) Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dot indicators for From -> To
                    Column(
                      children: [
                        const Icon(Icons.radio_button_checked, size: 16, color: AppColors.success),
                        Container(width: 2, height: 28, color: isDark ? AppColors.darkBorder : AppColors.border),
                        const Icon(Icons.location_on, size: 16, color: AppColors.danger),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Two input fields
                    Expanded(
                      child: Column(
                        children: [
                          // Pickup Field
                          SizedBox(
                            height: 40,
                            child: TextField(
                              controller: _fromController,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: l10n?.fromCity ?? 'Pickup City (e.g. Delhi, Mumbai)…',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted),
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
                                                _fromSuggestions.clear();
                                              });
                                            },
                                          )
                                        : null,
                              ),
                              onChanged: _onFromChanged,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Drop Field
                          SizedBox(
                            height: 40,
                            child: TextField(
                              controller: _toController,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: l10n?.toCity ?? 'Drop City (e.g. Jaipur, Surat)…',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted),
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
                                                _toSuggestions.clear();
                                              });
                                            },
                                          )
                                        : null,
                              ),
                              onChanged: _onToChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Swap Button
                    IconButton(
                      icon: const Icon(Icons.swap_vert, size: 24, color: AppColors.brandYellowDark),
                      tooltip: l10n?.swap ?? 'Swap',
                      onPressed: _swapLocations,
                    ),
                  ],
                ),

                // Live Suggestions for From
                if (_fromSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _fromSuggestions.length,
                      separatorBuilder: (_, index) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                      itemBuilder: (context, i) {
                        final p = _fromSuggestions[i];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(Icons.place_outlined, size: 16, color: AppColors.success),
                          title: Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                          subtitle: Text(p.description, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _selectFromPlace(p, tripsVM),
                        );
                      },
                    ),
                  ),

                // Live Suggestions for To
                if (_toSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _toSuggestions.length,
                      separatorBuilder: (_, index) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                      itemBuilder: (context, i) {
                        final p = _toSuggestions[i];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(Icons.place_outlined, size: 16, color: AppColors.danger),
                          title: Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                          subtitle: Text(p.description, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _selectToPlace(p, tripsVM),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 10),

                // Search Return Loads Button (prominent & engaging)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: AppColors.slateDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(
                      l10n?.searchReturnLoads ?? 'Search Return Loads',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    onPressed: () {
                      final from = _fromController.text.trim();
                      final to = _toController.text.trim();
                      if (from.isNotEmpty || to.isNotEmpty) {
                        tripsVM.setRouteSearch(from: from, to: to);
                        final p1 = _fromLatLng ?? _posFor(from.isNotEmpty ? from : 'Delhi');
                        final p2 = _toLatLng ?? _posFor(to.isNotEmpty ? to : 'Hyderabad');
                        _fromLatLng = p1;
                        _toLatLng = p2;
                        _fromName = from.isNotEmpty ? from : 'Delhi';
                        _toName = to.isNotEmpty ? to : 'Hyderabad';
                        _calculateAndDrawRoute(p1, p2, _fromName!, _toName!);
                      } else {
                        tripsVM.clearFilters();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Tonnage Filter Chips (All, Mini <3T, Medium 3-10T, Heavy >10T)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('All Weight', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        selected: tripsVM.tonnageFilter == 'all',
                        selectedColor: AppColors.brandYellow,
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onSelected: (_) => tripsVM.setTonnageFilter('all'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text('Mini (<3T)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        selected: tripsVM.tonnageFilter == 'mini',
                        selectedColor: AppColors.brandYellow,
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onSelected: (_) => tripsVM.setTonnageFilter('mini'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text('Medium (3-10T)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        selected: tripsVM.tonnageFilter == 'medium',
                        selectedColor: AppColors.brandYellow,
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onSelected: (_) => tripsVM.setTonnageFilter('medium'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text('Heavy (>10T)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        selected: tripsVM.tonnageFilter == 'heavy',
                        selectedColor: AppColors.brandYellow,
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onSelected: (_) => tripsVM.setTonnageFilter('heavy'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Corridor Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "Best Match (ML)" Chip
                      FilterChip(
                        avatar: const Icon(Icons.star, size: 14, color: AppColors.slateDark),
                        label: Text(
                          l10n?.bestMatch ?? '★ Best Match (ML)',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                        selected: tripsVM.categoryFilter == 'best_match',
                        selectedColor: AppColors.brandYellow,
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onSelected: (selected) =>
                            tripsVM.setCategoryFilter(selected ? 'best_match' : 'all'),
                      ),
                      const SizedBox(width: 6),

                      // Quick Corridors
                      ActionChip(
                        label: Text('Delhi ⇄ Hyderabad', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onPressed: () {
                          _fromController.text = 'Delhi NCR Hub';
                          _toController.text = 'Hyderabad Hub';
                          _fromName = 'Delhi NCR Hub';
                          _toName = 'Hyderabad Hub';
                          _fromLatLng = _cityLatLng['Delhi NCR'] ?? const LatLng(28.6139, 77.2090);
                          _toLatLng = _cityLatLng['Hyderabad'] ?? const LatLng(17.3850, 78.4867);
                          tripsVM.setRouteSearch(from: 'Delhi NCR Hub', to: 'Hyderabad Hub');
                          _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, 'Delhi NCR Hub', 'Hyderabad Hub');
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: Text('Delhi ⇄ Mumbai', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onPressed: () {
                          _fromController.text = 'Delhi';
                          _toController.text = 'Mumbai';
                          _fromName = 'Delhi';
                          _toName = 'Mumbai';
                          _fromLatLng = _cityLatLng['Delhi'];
                          _toLatLng = _cityLatLng['Mumbai'];
                          tripsVM.setRouteSearch(from: 'Delhi', to: 'Mumbai');
                          if (_fromLatLng != null && _toLatLng != null) {
                            _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, 'Delhi', 'Mumbai');
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: Text('Mumbai ⇄ Pune', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onPressed: () {
                          _fromController.text = 'Mumbai';
                          _toController.text = 'Pune';
                          _fromName = 'Mumbai';
                          _toName = 'Pune';
                          _fromLatLng = _cityLatLng['Mumbai'];
                          _toLatLng = _cityLatLng['Pune'];
                          tripsVM.setSearchFilter('Pune');
                          if (_fromLatLng != null && _toLatLng != null) {
                            _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, 'Mumbai', 'Pune');
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: Text('Jaipur ⇄ Delhi', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onPressed: () {
                          _fromController.text = 'Jaipur';
                          _toController.text = 'Delhi';
                          _fromName = 'Jaipur';
                          _toName = 'Delhi';
                          _fromLatLng = _cityLatLng['Jaipur'];
                          _toLatLng = _cityLatLng['Delhi'];
                          tripsVM.setSearchFilter('Jaipur');
                          if (_fromLatLng != null && _toLatLng != null) {
                            _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, 'Jaipur', 'Delhi');
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: Text('Ahmedabad ⇄ Surat', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
                        onPressed: () {
                          _fromController.text = 'Ahmedabad';
                          _toController.text = 'Surat';
                          _fromName = 'Ahmedabad';
                          _toName = 'Surat';
                          _fromLatLng = _cityLatLng['Ahmedabad'];
                          _toLatLng = _cityLatLng['Surat'];
                          tripsVM.setSearchFilter('Ahmedabad');
                          if (_fromLatLng != null && _toLatLng != null) {
                            _calculateAndDrawRoute(_fromLatLng!, _toLatLng!, 'Ahmedabad', 'Surat');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Interactive Map View with Driving Route & Polylines
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(target: LatLng(22.5, 78.5), zoom: 4.5),
                  zoomControlsEnabled: true,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  liteModeEnabled: false, // FULL interactive map!
                  polylines: _polylines,
                  markers: displayMarkers,
                  onMapCreated: (controller) => _mapController = controller,
                ),

                // Floating Route Badge
                if (_currentRoute != null)
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: AppColors.brandYellow, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alt_route, color: AppColors.brandYellowDark, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_fromName ?? 'Origin'} → ${_toName ?? 'Destination'}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkInk : AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _currentRoute!.distanceText,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('•', style: TextStyle(color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted)),
                                    const SizedBox(width: 6),
                                    Text(
                                      _currentRoute!.durationText,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Clear Route',
                            onPressed: _clearRoute,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loading Route Progress Indicator
                if (_calculatingRoute)
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 8),
                            Text('Calculating road route…', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Results Count Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${loads.length} return load${loads.length == 1 ? '' : 's'} available',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted,
                  ),
                ),
                if (_fromName != null || _toName != null || tripsVM.searchFilter.isNotEmpty || tripsVM.myCorridorOnly)
                  GestureDetector(
                    onTap: _clearRoute,
                    child: Text(
                      l10n?.clear ?? 'Clear Filters',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.danger),
                    ),
                  ),
              ],
            ),
          ),

          // 4. Loads List
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
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
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
                        'Try clearing your search filter or selecting a major freight corridor.',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: loads.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final load = loads[index];
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.bolt, size: 14, color: AppColors.success),
                                        const SizedBox(width: 4),
                                        Text(
                                          load.distanceKm > 0
                                              ? '${load.distanceKm.round()} km road corridor'
                                              : 'Verified Corridor Load',
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Real ML match score — only shown when it came from backend ranking
                                  if (load.hasRealMatchScore) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF3B82F6)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${load.matchScore}% match',
                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF3B82F6)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                load.pickupWindow,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Route Display + Map Tap Action
                          InkWell(
                            onTap: () => onSelectRoute(load),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.circle, color: AppColors.success, size: 10),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          load.origin,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: isDark ? AppColors.darkInk : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.map, size: 14, color: AppColors.brandYellowDark),
                                          const SizedBox(width: 4),
                                          Text(
                                            'View Route',
                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandYellowDark),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        height: 14,
                                        width: 2,
                                        color: isDark ? AppColors.darkBorder : AppColors.border,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: AppColors.danger, size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          load.destination,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: isDark ? AppColors.darkInk : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Text(
                            '${load.smeName} • ${load.cargoType} • ${load.weightTons} Tons',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n?.estimatedPayout ?? 'Guaranteed Payout',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted,
                                    ),
                                  ),
                                  Text(
                                    currency.format(load.offeredPriceInr),
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? AppColors.brandYellow : AppColors.slateDark,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 140,
                                child: RedoButton(
                                  title: l10n?.acceptLoad ?? 'Accept Load',
                                  onPressed: () async {
                                    final err = await tripsVM.acceptLoad(load);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(err ?? 'Load accepted! Shipper notified - check My Trips.')),
                                      );
                                      if (err == null && onNavigateToTrips != null) {
                                        onNavigateToTrips!();
                                      }
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
              );
  }
}
