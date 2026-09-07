import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/routing_service.dart';
import '../../../viewmodels/booking_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../matches/matching_trucks_screen.dart';

const List<String> cargoTypes = [
  'Industrial Goods',
  'Steel & Metals',
  'FMCG & Groceries',
  'Auto Components',
  'Chemicals',
  'Textiles',
  'Agriculture',
];

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> _liveTrips = [];
  RealtimeChannel? _tripsCh;

  @override
  void initState() {
    super.initState();
    _loadTrips();
    _tripsCh = SupabaseService.subscribeTrips(_loadTrips);
  }

  @override
  void dispose() {
    if (_tripsCh != null) SupabaseService.removeChannel(_tripsCh!);
    super.dispose();
  }

  Future<void> _loadTrips() async {
    try {
      final t = await SupabaseService.getLiveReturnTrips();
      if (mounted) setState(() => _liveTrips = t);
    } catch (_) {}
  }

  void _onSearch() async {
    final bookingVM = context.read<BookingViewModel>();
    final success = await bookingVM.searchMatchingTrucks();
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MatchingTrucksScreen()),
      );
    } else if (bookingVM.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bookingVM.errorMessage!)),
      );
    }
  }

  void _fitRoute(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.25, minLng - 0.25),
          northeast: LatLng(maxLat + 0.25, maxLng + 0.25),
        ),
        60,
      ),
    );
  }

  void _openPlaceSearchSheet(BuildContext context, bool isPickup) {
    final bookingVM = context.read<BookingViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PlaceSearchModal(
        isPickup: isPickup,
        onPlaceSelected: (place) {
          if (isPickup) {
            bookingVM.setOriginPlace(place);
          } else {
            bookingVM.setDestinationPlace(place);
          }
          Future.delayed(const Duration(milliseconds: 600), () {
            _fitRoute(bookingVM.routePoints);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<BookingViewModel>();
    final originPos = bookingVM.originLatLng;
    final destPos = bookingVM.destinationLatLng;
    final routePoints = bookingVM.routePoints;

    final markers = {
      Marker(
        markerId: const MarkerId('origin'),
        position: originPos,
        infoWindow: InfoWindow(title: 'Pickup: ${bookingVM.origin}', snippet: bookingVM.originPlace.description),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destPos,
        infoWindow: InfoWindow(title: 'Drop: ${bookingVM.destination}', snippet: bookingVM.destPlace.description),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    final polylines = {
      Polyline(
        polylineId: const PolylineId('road_route'),
        points: routePoints,
        color: const Color(0xFF1E293B), // Premium dark navy route
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map View with Real Road Route
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: originPos,
              zoom: 6.0,
            ),
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitRoute(routePoints);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. Floating Top Route Stats Chip (Rapido / Uber style)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.brandYellow, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.route, color: AppColors.slateDark, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  bookingVM.roadDistanceText,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.ink),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    'Real Road Highway',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.success),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${bookingVM.roadDurationText} driving time • Backhaul rate ~₹1.05/t-km',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      if (bookingVM.isRouting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandYellow),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Rapido-Style Location Selection Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Rapido Location Picker Card ---
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // PICKUP TILE
                        InkWell(
                          onTap: () => _openPlaceSearchSheet(context, true),
                          borderRadius: BorderRadius.circular(10),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PICKUP FROM',
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkMuted),
                                    ),
                                    Text(
                                      bookingVM.originPlace.name,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      bookingVM.originPlace.description,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // 1-Tap Current Location Auto-Detect Button
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  backgroundColor: AppColors.cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.my_location, size: 14, color: AppColors.slateDark),
                                label: Text('GPS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slateDark)),
                                onPressed: () async {
                                  final ok = await bookingVM.useCurrentLocationForPickup();
                                  if (ok && mounted) {
                                    _fitRoute(bookingVM.routePoints);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('📍 Pickup set to ${bookingVM.originPlace.name}')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: AppColors.border),
                        ),

                        // DROP TILE
                        InkWell(
                          onTap: () => _openPlaceSearchSheet(context, false),
                          borderRadius: BorderRadius.circular(10),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DROP TO',
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkMuted),
                                    ),
                                    Text(
                                      bookingVM.destPlace.name,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      bookingVM.destPlace.description,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.swap_vert, size: 20, color: AppColors.inkMuted),
                                tooltip: 'Swap Route',
                                onPressed: () {
                                  bookingVM.swapLocations();
                                  _fitRoute(bookingVM.routePoints);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cargo Type & Weight
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CARGO TYPE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: bookingVM.cargoType,
                                  isExpanded: true,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 13),
                                  items: cargoTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                  onChanged: (v) {
                                    if (v != null) bookingVM.setCargoType(v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WEIGHT (${bookingVM.weightTons.toStringAsFixed(1)} T)', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (bookingVM.weightTons > 1.0) bookingVM.setWeightTons(bookingVM.weightTons - 1.0);
                                    },
                                    child: const Icon(Icons.remove_circle_outline, size: 20),
                                  ),
                                  Text('${bookingVM.weightTons.toInt()} T', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                                  InkWell(
                                    onTap: () {
                                      if (bookingVM.weightTons < 40.0) bookingVM.setWeightTons(bookingVM.weightTons + 1.0);
                                    },
                                    child: const Icon(Icons.add_circle_outline, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search CTA
                  RedoButton(
                    title: 'Find Matching Empty Return Trucks',
                    isLoading: bookingVM.isLoading,
                    icon: Icons.search,
                    onPressed: _onSearch,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Rapido-Style Place Autocomplete Search Modal
class _PlaceSearchModal extends StatefulWidget {
  final bool isPickup;
  final ValueChanged<PlaceSuggestion> onPlaceSelected;

  const _PlaceSearchModal({required this.isPickup, required this.onPlaceSelected});

  @override
  State<_PlaceSearchModal> createState() => _PlaceSearchModalState();
}

class _PlaceSearchModalState extends State<_PlaceSearchModal> {
  final _searchController = TextEditingController();
  List<PlaceSuggestion> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate popular Indian freight hubs
    _results = [
      PlaceSuggestion(name: 'Mumbai Hub', description: 'Bhiwandi / Kalamboli Freight Corridor, MH', latLng: const LatLng(19.0760, 72.8777)),
      PlaceSuggestion(name: 'Delhi NCR Hub', description: 'Sanjay Gandhi Transport Nagar, Okhla, DL', latLng: const LatLng(28.6139, 77.2090)),
      PlaceSuggestion(name: 'Pune Hub', description: 'Chakan Industrial Logistics Corridor, MH', latLng: const LatLng(18.5204, 73.8567)),
      PlaceSuggestion(name: 'Jaipur Hub', description: 'VKI Area Transport Nagar, RJ', latLng: const LatLng(26.9124, 75.7873)),
      PlaceSuggestion(name: 'Surat Hub', description: 'Sachin GIDC Textile Hub, GJ', latLng: const LatLng(21.1702, 72.8311)),
      PlaceSuggestion(name: 'Ahmedabad Hub', description: 'Narol Aslali Transport Complex, GJ', latLng: const LatLng(23.0225, 72.5714)),
      PlaceSuggestion(name: 'Bengaluru Hub', description: 'Peenya Industrial Logistics Complex, KA', latLng: const LatLng(12.9716, 77.5946)),
    ];
  }

  void _onQueryChanged(String query) async {
    if (query.trim().length < 2) return;
    setState(() => _isSearching = true);
    final places = await RoutingService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _results = places;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(widget.isPickup ? Icons.trip_origin : Icons.place, color: widget.isPickup ? AppColors.success : AppColors.danger),
                const SizedBox(width: 8),
                Text(
                  widget.isPickup ? 'Select Pickup Location' : 'Select Drop Location',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search city, landmark, or industrial area…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final place = _results[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_city, color: AppColors.slateDark, size: 20),
                    ),
                    title: Text(place.name, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                    subtitle: Text(place.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      widget.onPlaceSelected(place);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
