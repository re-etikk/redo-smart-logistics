import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/services/places_service.dart';
import '../../../data/services/routing_service.dart';
import '../../../viewmodels/booking_viewmodel.dart';
import '../../widgets/redo_design_system.dart';
import 'cargo_details_screen.dart';

/// ReDo Customer App — SCREEN 02: CREATE SHIPMENT
/// Recreated natively in Flutter matching design reference media_1791216686105.png
class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  // Cargo category items
  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'electronics',
      'title': 'Electronics',
      'icon': Icons.laptop_mac_rounded,
    },
    {
      'id': 'packages',
      'title': 'Packages',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'id': 'documents',
      'title': 'Documents',
      'icon': Icons.description_outlined,
    },
    {
      'id': 'fragile',
      'title': 'Fragile',
      'icon': Icons.wine_bar_outlined,
    },
    {
      'id': 'other',
      'title': 'Other',
      'icon': Icons.more_horiz_rounded,
    },
  ];

  String? _selectedCategory;
  bool _isDetectingGps = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BookingViewModel>();
      // Auto-detect and autofill user's current live location on open
      if (vm.origin.isEmpty) {
        _detectLiveGpsLocation(silent: true).then((_) {
          if (mounted) {
            final cur = context.read<BookingViewModel>();
            if (cur.origin.isEmpty) {
              cur.setOriginPlace(
                PlaceSuggestion(
                  name: 'Delhi, DL',
                  description: 'New Delhi Logistics Hub',
                  latLng: const LatLng(28.6139, 77.2090),
                ),
              );
            }
          }
        });
      } else {
        _detectLiveGpsLocation(silent: true);
      }

      if (vm.destination.isEmpty) {
        vm.setDestinationPlace(
          PlaceSuggestion(
            name: 'Patna, BR',
            description: 'Patna Transport Nagar',
            latLng: const LatLng(25.5941, 85.1376),
          ),
        );
      }
      // Require user to select category explicitly; only pre-populate if user previously made explicit selection
      if (vm.cargoType.isNotEmpty && vm.cargoType != 'Industrial Goods') {
        setState(() {
          _selectedCategory = vm.cargoType;
        });
      }
    });
  }

  Future<void> _detectLiveGpsLocation({bool silent = false}) async {
    setState(() => _isDetectingGps = true);
    try {
      Position? pos;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && !silent && mounted) {
        _showSnackbar('Location services are turned off. Please turn on GPS.');
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (!silent) {
          _showSnackbar('Location permission denied. Please select from search list.');
        }
        return;
      }
      pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
      );
      final address = await PlacesService.reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      final vm = context.read<BookingViewModel>();
      final cityName = address.contains(',') ? address.split(',').first.trim() : address;
      final place = PlaceSuggestion(
        name: cityName,
        description: address,
        latLng: LatLng(pos.latitude, pos.longitude),
      );
      vm.setOriginPlace(place);
      _updateMapBounds();
      _showSnackbar('📍 Current location autofilled: ${place.name}');
    } catch (e) {
      if (mounted && !silent) {
        _showSnackbar('Could not detect GPS location. Please choose from list.');
      }
    } finally {
      if (mounted) setState(() => _isDetectingGps = false);
    }
  }

  void _updateMapBounds() {
    if (_mapController == null) return;
    final vm = context.read<BookingViewModel>();
    final o = vm.originLatLng;
    final d = vm.destinationLatLng;
    if (o.latitude == d.latitude && o.longitude == d.longitude) return;

    final bounds = LatLngBounds(
      southwest: LatLng(min(o.latitude, d.latitude), min(o.longitude, d.longitude)),
      northeast: LatLng(max(o.latitude, d.latitude), max(o.longitude, d.longitude)),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _handleContinue() {
    final vm = context.read<BookingViewModel>();
    final origin = vm.origin;
    final dest = vm.destination;

    if (origin.trim().isEmpty) {
      _showSnackbar('Please select a pickup location.');
      return;
    }
    if (dest.trim().isEmpty) {
      _showSnackbar('Please select a delivery location.');
      return;
    }
    if (origin.trim() == dest.trim()) {
      _showSnackbar('Pickup and delivery locations cannot be identical.');
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showSnackbar('Please select what you are sending (Cargo Category).');
      return;
    }

    // Persist category to viewmodel
    vm.setCargoType(_selectedCategory!);

    // Navigate to Screen 03: Cargo Details
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CargoDetailsScreen(),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final pickupName = vm.origin.isNotEmpty ? vm.origin : 'Delhi, DL';
    final deliveryName = vm.destination.isNotEmpty ? vm.destination : 'Patna, BR';
    final distanceText = vm.roadDistanceKm > 0
        ? '${vm.roadDistanceKm.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} km'
        : '1,050 km';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkCanvas : ReDoColors.warmBg;
    final bottomBarBg = isDark ? AppColors.darkCard : Colors.white;
    final bottomBorder = isDark ? AppColors.darkBorder : ReDoColors.cardBorder;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: const ReDoAppBar(
        title: 'Create shipment',
        currentStep: 1,
        totalSteps: 4,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========================================================
                    // 1. HEADLINE & DECORATIVE ACCENT
                    // ========================================================
                    _buildHeadlineSection(),
                    const SizedBox(height: 20),

                    // ========================================================
                    // 2. ROUTE SELECTOR CARD
                    // ========================================================
                    _buildRouteCard(context, pickupName, deliveryName, vm),
                    const SizedBox(height: 18),

                    // ========================================================
                    // 3. MAP VISUALIZATION CARD
                    // ========================================================
                    _buildMapCard(pickupName, deliveryName),
                    const SizedBox(height: 22),

                    // ========================================================
                    // 4. "What are you sending?" CARGO CATEGORIES
                    // ========================================================
                    _buildCargoCategorySection(),
                    const SizedBox(height: 20),

                    // ========================================================
                    // 5. DISTANCE & INFO FOOTER CARD
                    // ========================================================
                    _buildDistanceCard(pickupName, deliveryName, distanceText),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ================================================================
            // 6. BOTTOM ACTION: CONTINUE BUTTON
            // ================================================================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: bottomBarBg,
                border: Border(top: BorderSide(color: bottomBorder)),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ReDoButton(
                text: 'Continue',
                showArrow: true,
                onPressed: _handleContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Headline Section
  // --------------------------------------------------------------------------
  Widget _buildHeadlineSection() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where is it going?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: ReDoColors.darkNavy,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your pickup and delivery locations.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ReDoColors.secondaryText,
              ),
            ),
          ],
        ),
        // Decorative warm illustration in top right
        Positioned(
          top: -4,
          right: 0,
          child: CustomPaint(
            size: const Size(64, 52),
            painter: _DecorativeBoxesPainter(),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Route Selector Card with Timeline and Swap
  // --------------------------------------------------------------------------
  Widget _buildRouteCard(
    BuildContext context,
    String pickupName,
    String deliveryName,
    BookingViewModel vm,
  ) {
    return ReDoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Visual Route Indicator (Circle -> Dotted Line -> Pin)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ReDoColors.primaryYellow.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ReDoColors.primaryYellow,
                    ),
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (_) {
                        return const SizedBox(
                          width: 2,
                          height: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFFFB21A),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              const Icon(
                Icons.location_on,
                size: 24,
                color: ReDoColors.primaryYellow,
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Pickup and Delivery clickable inputs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup with Auto-Detect GPS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Pickup',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ReDoColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: GestureDetector(
                        onTap: _isDetectingGps ? null : _detectLiveGpsLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECC4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isDetectingGps)
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Color(0xFFC77800),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.my_location,
                                  size: 11,
                                  color: Color(0xFFC77800),
                                ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Auto-detect GPS',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF8B5500),
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
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openLocationPicker(context, isPickup: true),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pickupName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: ReDoColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Delivery
                Text(
                  'Delivery',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ReDoColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openLocationPicker(context, isPickup: false),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: ReDoColors.primaryYellow,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            deliveryName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: ReDoColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Swap Locations Action Button
          GestureDetector(
            onTap: () {
              vm.swapLocations();
              _updateMapBounds();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFE6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.swap_vert_rounded,
                  size: 22,
                  color: ReDoColors.darkNavy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Map Visualization Card (Real Google Map with Corridor Pins & Route)
  // --------------------------------------------------------------------------
  Widget _buildMapCard(String pickupName, String deliveryName) {
    final vm = context.watch<BookingViewModel>();
    LatLng fromLatLng;
    try {
      fromLatLng = vm.originPlace.latLng;
    } catch (_) {
      try {
        fromLatLng = vm.originLatLng;
      } catch (_) {
        fromLatLng = const LatLng(28.6139, 77.2090);
      }
    }

    LatLng toLatLng;
    try {
      toLatLng = vm.destPlace.latLng;
    } catch (_) {
      try {
        toLatLng = vm.destinationLatLng;
      } catch (_) {
        toLatLng = const LatLng(25.5941, 85.1376);
      }
    }

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup_marker'),
        position: fromLatLng,
        infoWindow: InfoWindow(title: 'Pickup: $pickupName'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('delivery_marker'),
        position: toLatLng,
        infoWindow: InfoWindow(title: 'Delivery: $deliveryName'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('corridor_route'),
        points: [fromLatLng, toLatLng],
        color: ReDoColors.primaryYellow,
        width: 4,
      ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ReDoColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                _updateMapBounds();
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (fromLatLng.latitude + toLatLng.latitude) / 2,
                  (fromLatLng.longitude + toLatLng.longitude) / 2,
                ),
                zoom: 5.5,
              ),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),
            // Floating Route Tag
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ReDoColors.darkNavy.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.route_rounded, size: 13, color: ReDoColors.primaryYellow),
                    const SizedBox(width: 5),
                    Text(
                      '${pickupName.split(',').first.trim()} → ${deliveryName.split(',').first.trim()}',
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
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Cargo Category Selection Section
  // --------------------------------------------------------------------------
  Widget _buildCargoCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are you sending?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: ReDoColors.darkNavy,
          ),
        ),
        const SizedBox(height: 14),

        // Row 1: 3 Items (Electronics, Packages, Documents)
        Row(
          children: [
            Expanded(child: _buildCategoryCard(_categories[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildCategoryCard(_categories[1])),
            const SizedBox(width: 10),
            Expanded(child: _buildCategoryCard(_categories[2])),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: 2 Items (Fragile, Other)
        Row(
          children: [
            Expanded(child: _buildCategoryCard(_categories[3])),
            const SizedBox(width: 10),
            Expanded(child: _buildCategoryCard(_categories[4])),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final title = cat['title'] as String;
    final icon = cat['icon'] as IconData;
    final isSelected = _selectedCategory != null &&
        _selectedCategory!.toLowerCase() == title.toLowerCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
        context.read<BookingViewModel>().setCargoType(title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9EE) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? ReDoColors.primaryYellow
                : ReDoColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ReDoColors.primaryYellow.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFECC4)
                        : const Color(0xFFF6F2E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: ReDoColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: ReDoColors.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: ReDoColors.darkNavy,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Distance / Summary Footer Card
  // --------------------------------------------------------------------------
  Widget _buildDistanceCard(
    String pickupName,
    String deliveryName,
    String distanceText,
  ) {
    final fromCity = pickupName.split(',').first.trim();
    final toCity = deliveryName.split(',').first.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE8B4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Distance Icon
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECC4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.alt_route_rounded,
                    size: 22,
                    color: Color(0xFFC77800),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Distance text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approx. distance',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ReDoColors.secondaryText,
                      ),
                    ),
                    Text(
                      distanceText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: ReDoColors.darkNavy,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Mini Route Schematic
              _buildMiniRouteSchematic(fromCity, toCity),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Final price depends on distance, cargo and vehicle availability.',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8C939E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRouteSchematic(String fromCity, String toCity) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on,
              size: 14,
              color: ReDoColors.primaryYellow,
            ),
            const SizedBox(width: 4),
            Container(
              width: 50,
              height: 2,
              decoration: BoxDecoration(
                color: ReDoColors.primaryYellow,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.location_on,
              size: 14,
              color: Color(0xFF88929E),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fromCity,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: ReDoColors.darkNavy,
              ),
            ),
            const SizedBox(width: 24),
            Text(
              toCity,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: ReDoColors.darkNavy,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Interactive Location Search Bottom Sheet
  // --------------------------------------------------------------------------
  void _openLocationPicker(BuildContext context, {required bool isPickup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return _LocationPickerBottomSheet(
          isPickup: isPickup,
          onPlaceSelected: (PlaceSuggestion place) {
            final vm = context.read<BookingViewModel>();
            if (isPickup) {
              vm.setOriginPlace(place);
            } else {
              vm.setDestinationPlace(place);
            }
          },
        );
      },
    );
  }
}

// ============================================================================
// Modal Location Picker Sheet (Search + Autocomplete + Major Hubs + GPS)
// ============================================================================
class _LocationPickerBottomSheet extends StatefulWidget {
  final bool isPickup;
  final ValueChanged<PlaceSuggestion> onPlaceSelected;

  const _LocationPickerBottomSheet({
    required this.isPickup,
    required this.onPlaceSelected,
  });

  @override
  State<_LocationPickerBottomSheet> createState() =>
      _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends State<_LocationPickerBottomSheet> {
  final _searchCtrl = TextEditingController();
  List<GooglePlaceSuggestion> _predictions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isLoading = true);
      final results = await PlacesService.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _predictions = results;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _selectPrediction(GooglePlaceSuggestion p) async {
    final details = await PlacesService.getPlaceDetails(p.placeId);
    final lat = details?['lat'] ?? 28.6139;
    final lng = details?['lng'] ?? 77.2090;

    final place = PlaceSuggestion(
      name: p.description.split(',').first.trim(),
      description: p.description,
      latLng: LatLng(lat, lng),
    );

    widget.onPlaceSelected(place);
    if (mounted) Navigator.pop(context);
  }

  bool _isDetecting = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _isDetecting = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS permission required for auto-detect')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final address = await PlacesService.reverseGeocode(pos.latitude, pos.longitude);
      final place = PlaceSuggestion(
        name: address.split(',').first.trim(),
        description: address,
        latLng: LatLng(pos.latitude, pos.longitude),
      );
      widget.onPlaceSelected(place);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine current GPS location.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  void _selectCity(CityLocation city) {
    final place = PlaceSuggestion(
      name: city.name,
      description: '${city.name} Logistics Hub',
      latLng: city.latLng,
    );
    widget.onPlaceSelected(place);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ReDoColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            widget.isPickup ? 'Select Pickup Location' : 'Select Delivery Location',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ReDoColors.darkNavy,
            ),
          ),
          const SizedBox(height: 14),

          // Search Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ReDoColors.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onQueryChanged,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ReDoColors.darkNavy,
              ),
              decoration: InputDecoration(
                icon: const Icon(Icons.search_rounded, color: ReDoColors.secondaryText),
                hintText: 'Search city, hub or address...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: ReDoColors.secondaryText,
                ),
                border: InputBorder.none,
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _predictions = []);
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Use Current Location Tile (Especially helpful for Pickup)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECC4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isDetecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC77800)),
                    )
                  : const Icon(Icons.my_location, size: 18, color: Color(0xFFC77800)),
            ),
            title: Text(
              'Use Current Location (GPS)',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: ReDoColors.darkNavy),
            ),
            subtitle: Text(
              'Auto-detect via device satellite location',
              style: GoogleFonts.inter(fontSize: 11, color: ReDoColors.secondaryText),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18, color: ReDoColors.secondaryText),
            onTap: _isDetecting ? null : _useCurrentLocation,
          ),
          const Divider(color: ReDoColors.border, height: 16),

          // Autocomplete list or Popular Cities
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: ReDoColors.primaryYellow),
              ),
            )
          else if (_predictions.isNotEmpty)
            SizedBox(
              height: 240,
              child: ListView.separated(
                itemCount: _predictions.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: ReDoColors.border, height: 1),
                itemBuilder: (context, index) {
                  final p = _predictions[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: ReDoColors.primaryYellow,
                    ),
                    title: Text(
                      p.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ReDoColors.darkNavy,
                      ),
                    ),
                    onTap: () => _selectPrediction(p),
                  );
                },
              ),
            )
          else ...[
            // Quick Hubs Section
            Text(
              'Major Freight Corridors',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ReDoColors.secondaryText,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: majorCities.take(8).map((city) {
                return ActionChip(
                  label: Text(city.name),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ReDoColors.darkNavy,
                  ),
                  backgroundColor: const Color(0xFFF7F4EC),
                  side: const BorderSide(color: ReDoColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onPressed: () => _selectCity(city),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Decorative Graphic Painter (Boxes + Map Pin)
// ============================================================================
class _DecorativeBoxesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Small stacked isometric cardboard boxes
    final boxPaint = Paint()
      ..color = const Color(0xFFE2B276).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final boxDark = Paint()
      ..color = const Color(0xFFC78E4E).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Base box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.35, 28, 22),
        const Radius.circular(3),
      ),
      boxPaint,
    );
    // Stacked top box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.15, 24, 18),
        const Radius.circular(3),
      ),
      boxDark,
    );

    // Decorative Yellow Map Pin
    final pinPaint = Paint()
      ..color = ReDoColors.primaryYellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.82, h * 0.25), 8, pinPaint);

    final innerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.82, h * 0.25), 3, innerDot);

    // Dotted curve connecting to boxes
    final dashPaint = Paint()
      ..color = ReDoColors.primaryYellow.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(w * (0.55 + i * 0.08), h * (0.18 + i * 0.02)),
        1.0,
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
