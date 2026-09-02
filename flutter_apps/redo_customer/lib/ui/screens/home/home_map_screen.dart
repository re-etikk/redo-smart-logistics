import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/supabase_service.dart';
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
    // Rapido-style: trucks (open return trips) appear on the map LIVE.
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

  LatLng _cityPos(String name) {
    for (final c in majorCities) {
      if (name.startsWith(c.name.split(' ').first)) return c.latLng;
    }
    return majorCities.first.latLng;
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

  void _updateCamera(LatLng pos1, LatLng pos2) {
    if (_mapController == null) return;
    final southWestLat = pos1.latitude < pos2.latitude ? pos1.latitude : pos2.latitude;
    final southWestLng = pos1.longitude < pos2.longitude ? pos1.longitude : pos2.longitude;
    final northEastLat = pos1.latitude > pos2.latitude ? pos1.latitude : pos2.latitude;
    final northEastLng = pos1.longitude > pos2.longitude ? pos1.longitude : pos2.longitude;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(southWestLat - 1.5, southWestLng - 1.5),
          northeast: LatLng(northEastLat + 1.5, northEastLng + 1.5),
        ),
        50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<BookingViewModel>();
    final originPos = bookingVM.originLatLng;
    final destPos = bookingVM.destinationLatLng;

    // LIVE trucks: every open return trip = a truck marker at its current
    // (empty-at) city, slightly fanned out so clusters stay readable.
    final tripMarkers = <Marker>{};
    for (var i = 0; i < _liveTrips.length; i++) {
      final t = _liveTrips[i];
      final base = _cityPos('${t['origin']}');
      final jitter = 0.06 * (i % 5) - 0.12; // fan-out so trucks don't overlap
      final tripId = t['id'] ?? t['trip_id'] ?? '$i';
      final cap = t['available_capacity_tons'] != null ? '${t['available_capacity_tons']} T free capacity' : 'Live on REDO network';
      tripMarkers.add(Marker(
        markerId: MarkerId('trip-$tripId'),
        position: LatLng(base.latitude + jitter, base.longitude + jitter * 0.7),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(
          title: 'Return truck → ${t['destination']}',
          snippet: cap,
        ),
      ));
    }

    final markers = {
      ...tripMarkers,
      Marker(
        markerId: const MarkerId('origin'),
        position: originPos,
        infoWindow: InfoWindow(title: 'Pickup: ${bookingVM.origin}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destPos,
        infoWindow: InfoWindow(title: 'Drop: ${bookingVM.destination}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    final polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [originPos, destPos],
        color: AppColors.slateDark,
        width: 4,
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Maps View
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: originPos,
              zoom: 6.0,
            ),
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              _updateCamera(originPos, destPos);
            },
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. Floating Top Banner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.brandYellow, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.local_shipping, color: AppColors.slateDark, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Smart Return Backhauls',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                            ),
                            Text(
                              'Save up to 40% vs spot market rates',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.success),
                            ),
                            Text(
                              _liveTrips.isEmpty
                                  ? 'Scanning for live trucks…'
                                  : '🚚 ${_liveTrips.length} trucks LIVE on the network right now',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.slateDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Booking Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Origin / Destination Selector
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PICKUP FROM', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: bookingVM.origin,
                                  isExpanded: true,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14),
                                  items: majorCities.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      bookingVM.setOrigin(v);
                                      _updateCamera(bookingVM.originLatLng, bookingVM.destinationLatLng);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, color: AppColors.inkMuted, size: 18),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DROP TO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: bookingVM.destination,
                                  isExpanded: true,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14),
                                  items: majorCities.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      bookingVM.setDestination(v);
                                      _updateCamera(bookingVM.originLatLng, bookingVM.destinationLatLng);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                            Text('WEIGHT (${bookingVM.weightTons.toStringAsFixed(1)} TONS)', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
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
