import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/redo_partner_components.dart';
import '../misc/notifications_screen.dart';

class PartnerHomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTrips;
  final VoidCallback? onNavigateToEarnings;
  final VoidCallback? onNavigateToMessages;
  final VoidCallback? onNavigateToProfile;
  final Function(AvailableLoad)? onOpenTripDetails;
  final Function(ActiveTrip)? onOpenActiveTrip;

  const PartnerHomeScreen({
    super.key,
    this.onNavigateToTrips,
    this.onNavigateToEarnings,
    this.onNavigateToMessages,
    this.onNavigateToProfile,
    this.onOpenTripDetails,
    this.onOpenActiveTrip,
  });

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
  final PageController _opportunityPageController = PageController();
  int _currentOpportunityIndex = 0;

  // Delhi and Patna coords for route visual preview
  static const LatLng _delhiLatLng = LatLng(28.6139, 77.2090);
  static const LatLng _patnaLatLng = LatLng(25.5941, 85.1376);
  static const LatLng _driverLatLng = LatLng(28.5355, 77.3910); // Active truck near Delhi

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
    _opportunityPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.watch<PartnerTripsViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final driverProfile = authVM.profile;

    final driverName = driverProfile?.fullName.isNotEmpty == true
        ? driverProfile!.fullName
        : 'Rahul Kumar';
    final driverRating = tripsVM.driverRating;
    final driverAvatar = driverProfile?.avatarUrl;

    final todayEarnings = tripsVM.todayEarningsInr;
    final todayTrips = tripsVM.todayTripsCount;
    final todayDistance = tripsVM.todayDistanceKm;

    final activeTrip = tripsVM.currentActiveTrip;
    final availableLoads = tripsVM.availableLoads;

    return Scaffold(
      backgroundColor: ReDoPartnerColors.warmBackground,
      appBar: PartnerAppBar(
        showBrandHeader: true,
        driverName: driverName,
        driverRating: driverRating,
        driverAvatar: driverAvatar,
        unreadNotifications: 1,
        onNotificationTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
        onProfileTap: widget.onNavigateToProfile,
      ),
      body: RefreshIndicator(
        color: ReDoPartnerColors.brandYellow,
        backgroundColor: Colors.white,
        onRefresh: tripsVM.fetchAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TODAY'S EARNINGS HERO CARD
              EarningsCard(
                todayEarnings: todayEarnings,
                tripCount: todayTrips,
                distanceKm: todayDistance,
                rating: driverRating,
                onTap: widget.onNavigateToEarnings,
              ),
              const SizedBox(height: 16),

              // 2. LIVE MAP PANEL WITH ONLINE/OFFLINE TOGGLE
              _buildMapSection(tripsVM),
              const SizedBox(height: 16),

              // 3. CURRENT TRIP CARD
              _buildCurrentTripCard(context, tripsVM, activeTrip),
              const SizedBox(height: 20),

              // 4. TRIP OPPORTUNITIES CAROUSEL
              _buildOpportunitiesSection(context, availableLoads),
              const SizedBox(height: 20),

              // 5. QUICK ACTIONS
              _buildQuickActionsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // MAP SECTION WITH EMBEDDED ONLINE TOGGLE OVERLAY
  // ==========================================================================
  Widget _buildMapSection(PartnerTripsViewModel tripsVM) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ReDoPartnerColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Embedded real map panel
            MapPanel(
              height: 230,
              originLatLng: _delhiLatLng,
              destLatLng: _patnaLatLng,
              driverLatLng: _driverLatLng,
              originName: 'Delhi Pickup',
              destName: 'Patna Delivery',
              showControls: true,
              onRecenter: () {},
            ),

            // Top Floating Online / Offline Toggle
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: DriverStatusToggle(
                isOnline: tripsVM.isOnline,
                onToggle: (newStatus) async {
                  await tripsVM.toggleOnlineOffline();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newStatus
                              ? '🟢 You are ONLINE and discoverable for loads.'
                              : '⚪ You are OFFLINE. New requests paused.',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                onStatusTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tripsVM.isOnline
                            ? 'Ready for dispatches! Your truck is visible to shippers.'
                            : 'Currently offline. Tap Go Online to start receiving trips.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // CURRENT TRIP CARD
  // ==========================================================================
  Widget _buildCurrentTripCard(
    BuildContext context,
    PartnerTripsViewModel tripsVM,
    ActiveTrip? trip,
  ) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final origin = trip?.origin.isNotEmpty == true ? trip!.origin : 'Delhi, DL';
    final destination = trip?.destination.isNotEmpty == true ? trip!.destination : 'Patna, BR';
    final earnings = trip?.payoutInr != null && trip!.payoutInr > 0 ? trip.payoutInr : 4850.0;
    final statusText = trip?.status == 'in_transit'
        ? 'In transit to delivery'
        : 'On the way to pickup';

    return PartnerCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: "Current trip" and green chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Current trip',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: PartnerStatusChip(
                  label: statusText,
                  variant: PartnerChipVariant.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Route & Earnings layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Origin & Destination with dotted line
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Origin
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 3.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                origin,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ReDoPartnerColors.darkNavy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Pickup • 10:20 AM',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: ReDoPartnerColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Dotted line connector
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3),
                      child: Container(
                        width: 2,
                        height: 18,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                    // Destination
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ReDoPartnerColors.darkNavy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'ETA • 8:30 PM',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: ReDoPartnerColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                height: 48,
                color: ReDoPartnerColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),

              // Right: Earnings & View details button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currency.format(earnings),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: ReDoPartnerColors.darkNavy,
                    ),
                  ),
                  Text(
                    'Trip earnings',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: ReDoPartnerColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      if (trip != null && widget.onOpenActiveTrip != null) {
                        widget.onOpenActiveTrip!(trip);
                      } else if (widget.onNavigateToTrips != null) {
                        widget.onNavigateToTrips!();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ReDoPartnerColors.darkNavy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View details',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
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

  // ==========================================================================
  // TRIP OPPORTUNITIES CAROUSEL
  // ==========================================================================
  Widget _buildOpportunitiesSection(
    BuildContext context,
    List<AvailableLoad> availableLoads,
  ) {
    // If empty, generate standard opportunities based on real corridors
    final loads = availableLoads.isNotEmpty
        ? availableLoads
        : [
            AvailableLoad(
              cargoId: 'crg_sample_1',
              smeName: 'Apex Electronics',
              origin: 'Delhi, DL',
              destination: 'Patna, BR',
              cargoType: 'Electronics',
              weightTons: 12.0,
              offeredPriceInr: 4850.0,
              distanceKm: 1000,
              pickupWindow: 'Pickup in 10 km',
              urgency: 'scheduled',
            ),
            AvailableLoad(
              cargoId: 'crg_sample_2',
              smeName: 'Bharat Chemicals',
              origin: 'Kanpur, UP',
              destination: 'Lucknow, UP',
              cargoType: 'Industrial Drums',
              weightTons: 14.0,
              offeredPriceInr: 2800.0,
              distanceKm: 90,
              pickupWindow: 'Pickup in 4 km',
              urgency: 'instant',
              isInstant: true,
            ),
            AvailableLoad(
              cargoId: 'crg_sample_3',
              smeName: 'Jaipur Crafts Ltd',
              origin: 'Jaipur, RJ',
              destination: 'Ahmedabad, GJ',
              cargoType: 'Textiles & Garments',
              weightTons: 8.5,
              offeredPriceInr: 3950.0,
              distanceKm: 650,
              pickupWindow: 'Pickup in 15 km',
              urgency: 'scheduled',
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Trip opportunities',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: ReDoPartnerColors.darkNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: widget.onNavigateToTrips,
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ReDoPartnerColors.secondary,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: ReDoPartnerColors.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Carousel Container
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _opportunityPageController,
            itemCount: loads.length,
            onPageChanged: (idx) => setState(() => _currentOpportunityIndex = idx),
            itemBuilder: (context, index) {
              final load = loads[index];
              return _buildOpportunityCard(context, load);
            },
          ),
        ),
        const SizedBox(height: 8),

        // Carousel Dot Indicators
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              loads.length.clamp(1, 5),
              (index) => Container(
                width: _currentOpportunityIndex == index ? 8 : 6,
                height: _currentOpportunityIndex == index ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentOpportunityIndex == index
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpportunityCard(BuildContext context, AvailableLoad load) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReDoPartnerColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Cargo Box image/icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7DC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/tracking_parcel_box.png',
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => const Icon(
                  Icons.inventory_2_outlined,
                  size: 28,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Center: Route & details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        load.origin,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: ReDoPartnerColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        load.destination,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildSmallInfo(
                  Icons.location_on_outlined,
                  load.pickupWindow.isNotEmpty ? load.pickupWindow : 'Pickup in 10 km',
                ),
                const SizedBox(height: 2),
                _buildSmallInfo(
                  Icons.local_shipping_outlined,
                  '${load.weightTons.toStringAsFixed(0)} Ton capacity',
                ),
                const SizedBox(height: 2),
                _buildSmallInfo(
                  Icons.inventory_2_outlined,
                  load.cargoType,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Earnings & View trip button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currency.format(load.offeredPriceInr),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: ReDoPartnerColors.darkNavy,
                ),
              ),
              Text(
                'Estimated earnings',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: ReDoPartnerColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  if (widget.onOpenTripDetails != null) {
                    widget.onOpenTripDetails!(load);
                  } else if (widget.onNavigateToTrips != null) {
                    widget.onNavigateToTrips!();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ReDoPartnerColors.brandYellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'View trip',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ReDoPartnerColors.darkNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: ReDoPartnerColors.darkNavy,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: ReDoPartnerColors.secondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ReDoPartnerColors.secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // QUICK ACTIONS ROW
  // ==========================================================================
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: ReDoPartnerColors.darkNavy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ActionButton(
              title: 'Trips',
              icon: Icons.local_shipping_outlined,
              onTap: widget.onNavigateToTrips ?? () {},
            ),
            const SizedBox(width: 10),
            ActionButton(
              title: 'Earnings',
              icon: Icons.bar_chart_rounded,
              onTap: widget.onNavigateToEarnings ?? () {},
            ),
            const SizedBox(width: 10),
            ActionButton(
              title: 'Messages',
              icon: Icons.chat_bubble_outline_rounded,
              badgeCount: 1,
              onTap: widget.onNavigateToMessages ?? () {},
            ),
          ],
        ),
      ],
    );
  }
}
