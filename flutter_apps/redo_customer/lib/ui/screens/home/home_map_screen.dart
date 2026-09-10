import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/places_service.dart';
import '../../../data/services/routing_service.dart';
import '../../../viewmodels/booking_viewmodel.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../matches/matching_trucks_screen.dart';
import '../misc/notifications_screen.dart';
import '../misc/support_screen.dart';
import '../../../l10n/app_localizations.dart';

const _cargoTypes = [
  'Industrial goods',
  'FMCG & groceries',
  'Textiles',
  'Auto components',
  'Chemicals',
  'Parcel / Express',
  'Other',
];

class CommercialVehicle {
  final String name;
  final String category;
  final double tonnage;
  final String baseRate;
  final IconData icon;

  const CommercialVehicle({
    required this.name,
    required this.category,
    required this.tonnage,
    required this.baseRate,
    required this.icon,
  });
}

const _vehicles = [
  CommercialVehicle(
    name: 'Tata Ace (Chhota Hathi)',
    category: '1.5 Ton • City Courier',
    tonnage: 1.5,
    baseRate: '₹850+',
    icon: Icons.local_shipping_outlined,
  ),
  CommercialVehicle(
    name: 'Bolero Maxi Truck',
    category: '2.5 Ton • Intra-city & Agri',
    tonnage: 2.5,
    baseRate: '₹1,600+',
    icon: Icons.airport_shuttle_outlined,
  ),
  CommercialVehicle(
    name: '17ft Eicher / Canter',
    category: '7.0 Ton • Industrial Freight',
    tonnage: 7.0,
    baseRate: '₹4,500+',
    icon: Icons.fire_truck_outlined,
  ),
  CommercialVehicle(
    name: '32ft Multi-Axle Container',
    category: '18.0 Ton • Inter-State FMCG',
    tonnage: 18.0,
    baseRate: '₹12,800+',
    icon: Icons.directions_boat_outlined,
  ),
  CommercialVehicle(
    name: '40ft Heavy Trailer',
    category: '35.0 Ton • Steel & Heavy Cargo',
    tonnage: 35.0,
    baseRate: '₹24,500+',
    icon: Icons.electric_rickshaw_outlined,
  ),
];

class HomeMapScreen extends StatefulWidget {
  final ValueChanged<int>? onTabChangeRequested;
  const HomeMapScreen({super.key, this.onTabChangeRequested});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  int _selectedServiceIndex = 0; // 0: Book Transport, 1: Parcel, 2: Freight
  final _pickupAddressCtrl = TextEditingController();
  final _dropAddressCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  bool _showAddressDetails = false;

  GoogleMapController? _mapController;
  List<GooglePlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  String _activeField = ''; // 'pickup' or 'drop'
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<ShipmentsViewModel>().fetchShipments(silent: true);
    });
  }

  @override
  void dispose() {
    _pickupAddressCtrl.dispose();
    _dropAddressCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  Future<void> _findVehicles() async {
    final vm = context.read<BookingViewModel>();
    final found = await vm.searchMatchingTrucks();
    if (!mounted) return;
    if (found) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MatchingTrucksScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Could not find vehicles. Please retry.')),
      );
    }
  }

  Future<void> _registerLoad() async {
    final vm = context.read<BookingViewModel>();
    final ok = await vm.registerScheduledLoad();
    if (!mounted) return;
    if (ok) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Load Registered!', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your load on corridor ${vm.origin} → ${vm.destination} is now registered.',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.isInstant
                          ? '⚡ Instant Dispatch (1-2 Hours)'
                          : '📅 Pickup: ${DateFormat('EEE, d MMM yyyy').format(vm.scheduledDate)} · ${vm.timeSlot}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Weight: ${vm.weightTons.toStringAsFixed(1)} T · ${vm.cargoType}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                    ),
                    if (vm.pickupAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Pickup: ${vm.pickupAddress}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Drivers traveling on this route can now view this load and send acceptance offers in real time.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.brandYellow, foregroundColor: AppColors.slateDark),
              onPressed: () {
                Navigator.pop(ctx);
                if (widget.onTabChangeRequested != null) {
                  widget.onTabChangeRequested!(1); // Switch to Bookings tab
                }
              },
              child: const Text('View in My Bookings'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Could not register load. Please try again.')),
      );
    }
  }

  void _onSearchChanged(String query, String field) {
    _activeField = field;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        setState(() => _showSuggestions = false);
        return;
      }
      final suggestions = await PlacesService.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      }
    });
  }

  Future<void> _selectSuggestion(GooglePlaceSuggestion suggestion) async {
    final details = await PlacesService.getPlaceDetails(suggestion.placeId);
    if (!mounted || details == null) return;
    final vm = context.read<BookingViewModel>();
    final mainName = suggestion.description.split(',').first.trim();
    final place = PlaceSuggestion(
      name: mainName,
      description: suggestion.description,
      latLng: LatLng(details['lat'] ?? 20.5937, details['lng'] ?? 78.9629),
    );
    if (_activeField == 'pickup') {
      vm.setOriginPlace(place);
      _pickupAddressCtrl.text = suggestion.description;
      vm.setPickupAddress(suggestion.description);
    } else {
      vm.setDestinationPlace(place);
      _dropAddressCtrl.text = suggestion.description;
      vm.setDropAddress(suggestion.description);
    }
    setState(() => _showSuggestions = false);
    _updateMapCamera(vm);
  }

  void _updateMapCamera(BookingViewModel vm) {
    if (_mapController == null) return;
    final from = vm.originLatLng;
    final to = vm.destinationLatLng;
    if (vm.origin.isNotEmpty && vm.destination.isNotEmpty) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          from.latitude < to.latitude ? from.latitude : to.latitude,
          from.longitude < to.longitude ? from.longitude : to.longitude,
        ),
        northeast: LatLng(
          from.latitude > to.latitude ? from.latitude : to.latitude,
          from.longitude > to.longitude ? from.longitude : to.longitude,
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } else if (vm.origin.isNotEmpty) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(from, 12));
    } else if (vm.destination.isNotEmpty) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(to, 12));
    }
  }

  void _pickPlace(bool pickup) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PlacePicker(
        title: pickup ? 'Select Pickup Location' : 'Select Drop Location',
        onSelected: (place) {
          final vm = context.read<BookingViewModel>();
          pickup ? vm.setOriginPlace(place) : vm.setDestinationPlace(place);
          _updateMapCamera(vm);
        },
      ),
    );
  }

  Future<void> _detectGpsLocation() async {
    final vm = context.read<BookingViewModel>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detecting current GPS location...'), duration: Duration(seconds: 1)),
    );
    final success = await vm.useCurrentLocationForPickup();
    if (!mounted) return;
    if (success) {
      _updateMapCamera(vm);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pickup set to ${vm.originPlace.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not detect GPS location. Please choose manually.')),
      );
    }
  }

  void _onServiceSelected(int index) {
    setState(() => _selectedServiceIndex = index);
    final vm = context.read<BookingViewModel>();
    if (index == 0) {
      vm.setCargoType('Industrial goods');
      vm.setWeightTons(6.0);
    } else if (index == 1) {
      vm.setCargoType('Parcel / Express');
      vm.setWeightTons(1.5);
    } else if (index == 2) {
      vm.setCargoType('Industrial goods');
      vm.setWeightTons(18.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingViewModel>();
    final shipments = context.watch<ShipmentsViewModel>();
    final recentBookings = shipments.shipments.take(3).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                RedoBrandHeader(
                  subtitle: 'Transport & Logistics',
                  onNotificationTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.brandYellow,
                    onRefresh: shipments.fetchShipments,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        // Hero Banner
                        _buildHeroBanner(isDark),
                        const SizedBox(height: 16),

                        // Service Selector (Book Transport, Parcel, Freight)
                        _buildServiceSelector(cardBorder, textPrimary, textMuted),
                        const SizedBox(height: 16),

                        // Pickup & Drop Card with GPS & Swap & Interactive Vehicles
                        _buildBookingInputCard(booking, textPrimary, textMuted, cardBorder, isDark),
                        const SizedBox(height: 18),

                        // Quick Actions
                        _buildQuickActions(cardBorder, textPrimary),
                        const SizedBox(height: 24),

                        // Recent Bookings Section
                        _buildRecentBookingsHeader(textPrimary),
                        const SizedBox(height: 12),
                        _buildRecentBookingsContent(shipments, recentBookings, cardBorder, textPrimary, textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showSuggestions && _suggestions.isNotEmpty)
              Positioned(
                top: 200,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final s = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.brandYellow),
                          title: Text(s.description, style: GoogleFonts.inter(fontSize: 13, color: textPrimary)),
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: isDark ? 0.08 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'REDO LOGISTICS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slateDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Move Smarter\nwith Redo',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.slateDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Instant backhaul matching & live tracking.',
                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const RedoTruckHeroGraphic(height: 76),
        ],
      ),
    );
  }

  Widget _buildServiceSelector(Color cardBorder, Color textPrimary, Color textMuted) {
    final l10n = AppLocalizations.of(context);
    final services = [
      l10n?.bookShipment ?? 'Book Transport',
      l10n?.sendParcel ?? 'Parcel Express',
      'Heavy Freight',
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: List.generate(services.length, (i) {
          final isSelected = _selectedServiceIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () => _onServiceSelected(i),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  services[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.slateDark : textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBookingInputCard(
    BookingViewModel vm,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup Location Row with GPS
          InkWell(
            onTap: () => _pickPlace(true),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.trip_origin, color: AppColors.success, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.pickupLocation ?? 'Pickup location',
                          style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                        ),
                        Text(
                          vm.originPlace.name.isEmpty ? (l10n?.typeLocation ?? 'Select pickup city/hub') : vm.originPlace.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: vm.originPlace.name.isEmpty ? textMuted : textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: AppColors.brandYellow, size: 22),
                    tooltip: 'Detect current GPS location',
                    onPressed: _detectGpsLocation,
                  ),
                ],
              ),
            ),
          ),

          // Divider with Swap button
          Row(
            children: [
              const SizedBox(width: 16),
              Container(width: 2, height: 24, color: cardBorder),
              const Spacer(),
              InkWell(
                onTap: vm.swapLocations,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : AppColors.canvas,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_vert, size: 16, color: textPrimary),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.swap ?? 'Swap',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Drop Location Row
          InkWell(
            onTap: () => _pickPlace(false),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: AppColors.danger, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.dropLocation ?? 'Drop location',
                          style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                        ),
                        Text(
                          vm.destPlace.name.isEmpty ? (l10n?.typeLocation ?? 'Select drop city/hub') : vm.destPlace.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: vm.destPlace.name.isEmpty ? textMuted : textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Distance and Duration Info (if calculated)
          if (vm.roadDistanceKm > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_outlined, size: 16, color: AppColors.brandYellow),
                      const SizedBox(width: 6),
                      Text(
                        'Road Distance: ${vm.roadDistanceText}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ],
                  ),
                  Text(
                    vm.roadDurationText,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandYellowDark),
                  ),
                ],
              ),
            ),

          // Commercial Vehicle Selection Carousel
          Text(
            l10n?.selectVehicle ?? 'Select Commercial Vehicle',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.vehicleRecommendation ?? 'Recommended for your cargo load',
            style: GoogleFonts.inter(fontSize: 11, color: textMuted),
          ),
          const SizedBox(height: 10),
          _buildVehicleCarousel(vm, textPrimary, textMuted, cardBorder, isDark),
          const SizedBox(height: 14),

          // Cargo Type Dropdown
          DropdownButtonFormField<String>(
            initialValue: _cargoTypes.contains(vm.cargoType) ? vm.cargoType : _cargoTypes.first,
            decoration: InputDecoration(
              labelText: 'Cargo Category / Commodity',
              prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _cargoTypes
                .map((v) => DropdownMenuItem(value: v, child: Text(v, style: GoogleFonts.inter(fontSize: 13, color: textPrimary))))
                .toList(),
            onChanged: (val) {
              if (val != null) vm.setCargoType(val);
            },
          ),
          const SizedBox(height: 12),

          // Dedicated Clean Payload Weight Card (Never Wraps!)
          _buildWeightCard(vm, textPrimary, textMuted, cardBorder, isDark),
          const SizedBox(height: 14),

          // Professional REDO Shipment Scheduling (Instant vs Scheduled)
          _buildSchedulingSelector(vm, textPrimary, textMuted, cardBorder, isDark),
          const SizedBox(height: 12),

          // Google Map with Real Polyline
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20.5937, 78.9629), // India center
                    zoom: 4.5,
                  ),
                  onMapCreated: (ctrl) {
                    _mapController = ctrl;
                    _updateMapCamera(vm);
                  },
                  polylines: {
                    if (vm.origin.isNotEmpty && vm.destination.isNotEmpty && vm.routePoints.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId('corridor_route'),
                        points: vm.routePoints,
                        color: AppColors.brandYellow,
                        width: 5,
                      ),
                  },
                  markers: {
                    if (vm.origin.isNotEmpty)
                      Marker(
                        markerId: const MarkerId('pickup_marker'),
                        position: vm.originLatLng,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: InfoWindow(title: 'Pickup: ${vm.origin}'),
                      ),
                    if (vm.destination.isNotEmpty)
                      Marker(
                        markerId: const MarkerId('drop_marker'),
                        position: vm.destinationLatLng,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        infoWindow: InfoWindow(title: 'Drop: ${vm.destination}'),
                      ),
                  },
                ),
                if (vm.roadDistanceKm > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.slateDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.brandYellow),
                      ),
                      child: Text(
                        '🛣️ ${vm.roadDistanceText} • ${vm.roadDurationText}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandYellow,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Exact Addresses & GSTIN Form Section
          _buildAddressAndGstinSection(vm, textPrimary, textMuted, cardBorder),
          const SizedBox(height: 16),

          // Action Buttons: Find Trucks (Primary) + Register Load (Secondary)
          Row(
            children: [
              Expanded(
                flex: 6,
                child: RedoButton(
                  title: l10n?.findTrucks ?? 'Find Trucks  →',
                  icon: Icons.search,
                  isLoading: vm.isLoading,
                  onPressed: _findVehicles,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: const BorderSide(color: AppColors.brandYellow, width: 1.5),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18, color: AppColors.brandYellow),
                  label: Text(
                    l10n?.registerLoad ?? 'Register Load',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: textPrimary),
                  ),
                  onPressed: _registerLoad,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCarousel(
    BookingViewModel vm,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    bool isDark,
  ) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _vehicles.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final v = _vehicles[index];
          final isSelected = (vm.weightTons - v.tonnage).abs() < 0.3;

          return InkWell(
            onTap: () {
              vm.setWeightTons(v.tonnage);
              if (v.tonnage <= 1.5) {
                vm.setCargoType('Parcel / Express');
              } else {
                vm.setCargoType('Industrial goods');
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 148,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFFFFBEB))
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.brandYellow : cardBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.brandYellow.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        v.icon,
                        color: isSelected ? AppColors.brandYellow : textMuted,
                        size: 22,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandYellow : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${v.tonnage}T',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? AppColors.slateDark : textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? (isDark ? AppColors.brandYellow : AppColors.slateDark) : textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        v.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 9, color: textMuted),
                      ),
                    ],
                  ),
                  Text(
                    'Est. ${v.baseRate}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandYellowDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeightCard(
    BookingViewModel vm,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
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
                    l10n?.payloadTonnage ?? 'Payload Weight',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(vm.weightTons * 1000).round()} kg capacity required',
                    style: GoogleFonts.inter(fontSize: 10, color: textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: vm.weightTons > 0.5 ? AppColors.brandYellow : textMuted,
                      onPressed: vm.weightTons > 0.5 ? () => vm.setWeightTons(vm.weightTons - 0.5) : null,
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 64),
                      alignment: Alignment.center,
                      child: Text(
                        '${vm.weightTons.toStringAsFixed(1)} T',
                        maxLines: 1,
                        softWrap: false,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      color: vm.weightTons < 40 ? AppColors.brandYellow : textMuted,
                      onPressed: vm.weightTons < 40 ? () => vm.setWeightTons(vm.weightTons + 0.5) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick Tonnage Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildWeightPresetChip(1.5, '1.5 T (Ace)', vm, cardBorder, textPrimary, textMuted, isDark),
                const SizedBox(width: 6),
                _buildWeightPresetChip(2.5, '2.5 T (Pickup)', vm, cardBorder, textPrimary, textMuted, isDark),
                const SizedBox(width: 6),
                _buildWeightPresetChip(7.0, '7.0 T (Canter)', vm, cardBorder, textPrimary, textMuted, isDark),
                const SizedBox(width: 6),
                _buildWeightPresetChip(18.0, '18 T (Container)', vm, cardBorder, textPrimary, textMuted, isDark),
                const SizedBox(width: 6),
                _buildWeightPresetChip(35.0, '35 T (Trailer)', vm, cardBorder, textPrimary, textMuted, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightPresetChip(
    double weight,
    String label,
    BookingViewModel vm,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final isSelected = (vm.weightTons - weight).abs() < 0.2;
    return InkWell(
      onTap: () => vm.setWeightTons(weight),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandYellow
              : (isDark ? const Color(0xFF334155) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.brandYellow : cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.slateDark : textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSchedulingSelector(
    BookingViewModel vm,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.brandYellow),
              const SizedBox(width: 6),
              Text(
                'Shipment Schedule',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              const Spacer(),
              if (vm.isInstant)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.brandYellow),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 12, color: Colors.deepOrange),
                      const SizedBox(width: 2),
                      Text(
                        '1-2h Pickup',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.deepOrange),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Instant vs Scheduled Toggle
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => vm.setIsInstant(true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: vm.isInstant ? AppColors.brandYellow : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: vm.isInstant ? AppColors.brandYellow : cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, size: 15, color: vm.isInstant ? AppColors.slateDark : textMuted),
                        const SizedBox(width: 4),
                        Text(
                          l10n?.instantDispatch ?? '⚡ Ship Now (Instant)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: vm.isInstant ? FontWeight.w800 : FontWeight.w600,
                            color: vm.isInstant ? AppColors.slateDark : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => vm.setIsInstant(false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: !vm.isInstant ? AppColors.brandYellow : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: !vm.isInstant ? AppColors.brandYellow : cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_outlined, size: 15, color: !vm.isInstant ? AppColors.slateDark : textMuted),
                        const SizedBox(width: 4),
                        Text(
                          l10n?.scheduleLater ?? '📅 Schedule Later',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: !vm.isInstant ? FontWeight.w800 : FontWeight.w600,
                            color: !vm.isInstant ? AppColors.slateDark : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!vm.isInstant) ...[
            const SizedBox(height: 12),
            Text('Pickup Date', style: GoogleFonts.inter(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildDateChip('Today', DateTime.now(), vm, cardBorder, textPrimary, isDark),
                const SizedBox(width: 6),
                _buildDateChip('Tomorrow', DateTime.now().add(const Duration(days: 1)), vm, cardBorder, textPrimary, isDark),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      side: BorderSide(color: cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                    icon: Icon(Icons.calendar_today, size: 12, color: textPrimary),
                    label: Text(
                      DateFormat('d MMM').format(vm.scheduledDate),
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: vm.scheduledDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) vm.setScheduledDate(picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Time Window', style: GoogleFonts.inter(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                'Morning (08:00 - 12:00)',
                'Afternoon (12:00 - 16:00)',
                'Evening (16:00 - 20:00)',
                'Night (20:00 - 00:00)',
              ].map((slot) {
                final isSelected = vm.timeSlot == slot;
                final shortLabel = slot.split(' ').first;
                final timeRange = slot.substring(slot.indexOf('('));
                return InkWell(
                  onTap: () => vm.setTimeSlot(slot),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandYellow
                          : (isDark ? const Color(0xFF334155) : Theme.of(context).cardColor),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? AppColors.brandYellow : cardBorder),
                    ),
                    child: Text(
                      '$shortLabel $timeRange',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.slateDark : textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateChip(
    String label,
    DateTime date,
    BookingViewModel vm,
    Color cardBorder,
    Color textPrimary,
    bool isDark,
  ) {
    final isSelected = vm.scheduledDate.year == date.year &&
        vm.scheduledDate.month == date.month &&
        vm.scheduledDate.day == date.day;
    return InkWell(
      onTap: () => vm.setScheduledDate(date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandYellow
              : (isDark ? const Color(0xFF334155) : Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.brandYellow : cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.slateDark : textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildAddressAndGstinSection(
    BookingViewModel vm,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _showAddressDetails,
          onExpansionChanged: (val) => setState(() => _showAddressDetails = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(Icons.pin_drop_outlined, size: 18, color: AppColors.brandYellow),
          title: Text(
            l10n?.exactAddressesGstin ?? 'Exact Addresses & GSTIN',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
          ),
          subtitle: Text(
            vm.pickupAddress.isNotEmpty || vm.dropAddress.isNotEmpty
                ? 'Addresses specified'
                : (l10n?.exactAddressesGstinDesc ?? 'Add pickup/drop landmarks & GST (optional)'),
            style: GoogleFonts.inter(fontSize: 10, color: textMuted),
          ),
          children: [
            TextField(
              controller: _pickupAddressCtrl,
              style: GoogleFonts.inter(color: textPrimary),
              decoration: InputDecoration(
                labelText: l10n?.registeredAddress ?? 'Exact Pickup Street / Landmark',
                hintText: 'e.g. Plot 42, Shalimar Industrial Area, Gate 2',
                prefixIcon: const Icon(Icons.storefront_outlined, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (val) {
                vm.setPickupAddress(val);
                _onSearchChanged(val, 'pickup');
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dropAddressCtrl,
              style: GoogleFonts.inter(color: textPrimary),
              decoration: InputDecoration(
                labelText: l10n?.dropLocation ?? 'Exact Drop Street / Warehouse',
                hintText: 'e.g. Warehouse 5, Transport Nagar, Lucknow',
                prefixIcon: const Icon(Icons.warehouse_outlined, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (val) {
                vm.setDropAddress(val);
                _onSearchChanged(val, 'drop');
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _gstinCtrl,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.inter(color: textPrimary),
              decoration: InputDecoration(
                labelText: '${l10n?.gstin ?? "GSTIN"} / E-Way Bill (Optional)',
                hintText: 'e.g. 09ABCDE1234F1Z5',
                prefixIcon: const Icon(Icons.receipt_long_outlined, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: vm.setGstin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(Color cardBorder, Color textPrimary) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            Icons.local_shipping_outlined,
            l10n?.sendParcel ?? 'Send Parcel',
            () {
              _onServiceSelected(1);
              _pickPlace(true);
            },
            cardBorder,
            textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionTile(
            Icons.location_searching,
            l10n?.track ?? 'Track',
            () => widget.onTabChangeRequested?.call(2),
            cardBorder,
            textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionTile(
            Icons.receipt_long_outlined,
            l10n?.bookings ?? 'Bookings',
            () => widget.onTabChangeRequested?.call(1),
            cardBorder,
            textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionTile(
            Icons.headset_mic_outlined,
            l10n?.support ?? 'Support',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
            cardBorder,
            textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color cardBorder,
    Color textPrimary,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.brandYellow),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookingsHeader(Color textPrimary) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n?.recentBookings ?? 'Recent Bookings',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: textPrimary),
        ),
        TextButton(
          onPressed: () => widget.onTabChangeRequested?.call(1),
          child: Text(l10n?.viewAll ?? 'View all', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brandYellowDark)),
        ),
      ],
    );
  }

  Widget _buildRecentBookingsContent(
    ShipmentsViewModel vm,
    List<BookingItem> recentBookings,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final l10n = AppLocalizations.of(context);
    if (vm.isLoading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.brandYellow)),
      );
    }
    if (recentBookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 36, color: textMuted),
            const SizedBox(height: 8),
            Text(
              l10n?.noActiveBookings ?? 'No active bookings yet',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n?.noActiveBookingsDesc ?? 'Enter pickup and drop locations above to find return trucks.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentBookings.map((b) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => widget.onTabChangeRequested?.call(1),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: cardBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const RedoTruckHeroGraphic(height: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${b.origin} → ${b.destination}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${b.weightTons.toStringAsFixed(1)} T · ${b.cargoType}',
                        style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: b.status),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class _PlacePicker extends StatefulWidget {
  final String title;
  final ValueChanged<PlaceSuggestion> onSelected;
  const _PlacePicker({required this.title, required this.onSelected});

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  final _controller = TextEditingController();
  List<PlaceSuggestion> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await RoutingService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w900, color: textPrimary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.inter(color: textPrimary),
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search city, hub or address (e.g. Mumbai, Delhi, Lucknow)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandYellow),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        'Start typing to search real locations.',
                        style: GoogleFonts.inter(color: textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (ctx, i) => Divider(height: 1, color: cardBorder),
                      itemBuilder: (_, index) {
                        final place = _results[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.brandYellow),
                          title: Text(place.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
                          subtitle: Text(
                            place.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                          ),
                          onTap: () {
                            widget.onSelected(place);
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
