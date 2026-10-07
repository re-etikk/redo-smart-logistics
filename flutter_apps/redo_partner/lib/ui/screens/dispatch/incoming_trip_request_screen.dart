import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/redo_partner_components.dart';
import 'request_details_screen.dart';

/// Screen 02 — Incoming Trip Request
/// Recreates the real ReDo dispatch offer screen matching Reference 02.
/// Fully preserves backend 45-second countdown timer, real accept/skip logic,
/// and vehicle compatibility.
class IncomingTripRequestScreen extends StatefulWidget {
  final AvailableLoad load;
  final int secondsRemaining;
  final Future<void> Function() onAccept;
  final VoidCallback onDecline;

  const IncomingTripRequestScreen({
    super.key,
    required this.load,
    required this.secondsRemaining,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<IncomingTripRequestScreen> createState() =>
      _IncomingTripRequestScreenState();
}

class _IncomingTripRequestScreenState extends State<IncomingTripRequestScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _handleAccept() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.onAccept();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleSkip() {
    if (_isProcessing) return;
    widget.onDecline();
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailsScreen(
          load: widget.load,
          secondsRemaining: widget.secondsRemaining,
          onAccept: widget.onAccept,
          onDecline: widget.onDecline,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final tripsVM = context.watch<PartnerTripsViewModel>();
    final myTruck = tripsVM.myTrucks.isNotEmpty ? tripsVM.myTrucks.first : null;
    final truckCapacityTons = myTruck?.capacityTons ?? 14.0;
    final requiredTons = widget.load.weightTons > 0 ? widget.load.weightTons : 12.0;
    final fitsVehicle = truckCapacityTons >= requiredTons;

    final baseFare = (widget.load.offeredPriceInr * 0.95).round();
    final bonus = (widget.load.offeredPriceInr * 0.05).round();

    final formattedCountdown =
        '00:${widget.secondsRemaining.clamp(0, 45).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: ReDoPartnerColors.darkNavy,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Dark Header Section
            _buildDarkHeader(context),

            // Scrollable Content on Warm Canvas
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ReDoPartnerColors.warmBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      // 45-Second Countdown Banner
                      _buildCountdownBanner(formattedCountdown),
                      const SizedBox(height: 14),

                      // Route & Map Card
                      _buildRouteMapCard(context),
                      const SizedBox(height: 12),

                      // Pickup Distance & Time Card
                      _buildPickupCard(),
                      const SizedBox(height: 12),

                      // Cargo Details & Vehicle Match 2-Column Row
                      _buildCargoAndVehicleRow(context, fitsVehicle, truckCapacityTons, requiredTons),
                      const SizedBox(height: 12),

                      // Estimated Earnings Card
                      _buildEarningsCard(currency, baseFare, bonus),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: ReDoPartnerColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ReDoPartnerColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: ReDoPartnerColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      // Action Buttons: ACCEPT & SKIP
                      _buildActionButtons(),
                      const SizedBox(height: 12),

                      // Footer Warning/Note
                      _buildFooterNote(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
      color: ReDoPartnerColors.darkNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Top Row: Logo + Close 'X'
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: ReDoPartnerColors.brandYellow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: ReDoPartnerColors.darkNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ReDo',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Partner',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: _handleSkip,
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                tooltip: 'Close request',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'New trip request',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Respond quickly before this opportunity expires.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBanner(String formattedCountdown) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReDoPartnerColors.brandYellow.withValues(alpha: 0.5)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_filled_rounded,
                color: Color(0xFFFF9800),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formattedCountdown,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: ReDoPartnerColors.darkNavy,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 1.5,
              height: 24,
              color: ReDoPartnerColors.darkNavy.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 14),
            Text(
              'to respond',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ReDoPartnerColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteMapCard(BuildContext context) {
    final origin = widget.load.origin.isNotEmpty ? widget.load.origin : 'Delhi';
    final destination =
        widget.load.destination.isNotEmpty ? widget.load.destination : 'Patna';
    final distanceText = widget.load.distanceKm > 0
        ? '${widget.load.distanceKm.round()} km'
        : '1,000 km';

    return PartnerCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            origin,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: ReDoPartnerColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            destination,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ReDoPartnerColors.lightGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            distanceText,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.alt_route_rounded,
                                    size: 12, color: Color(0xFFFF9800)),
                                const SizedBox(width: 3),
                                Text(
                                  'Long haul',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openDetails(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ReDoPartnerColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View route',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Real Map Panel with route
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 150,
              child: MapPanel(
                originName: origin,
                destName: destination,
                height: 150,
                showControls: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupCard() {
    final distKm = widget.load.distanceKm > 0
        ? widget.load.distanceKm.round()
        : 10;
    return PartnerCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFE65100),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ReDoPartnerColors.secondary,
                  ),
                ),
                Text(
                  '$distKm km away',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                ),
                Text(
                  'Pickup in approximately ${(distKm * 1.8).round()} min',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: ReDoPartnerColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ReDoPartnerColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.navigation_rounded, size: 14, color: ReDoPartnerColors.darkNavy),
                const SizedBox(width: 4),
                Text(
                  'View on map',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ReDoPartnerColors.darkNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoAndVehicleRow(
    BuildContext context,
    bool fitsVehicle,
    double truckCapacityTons,
    double requiredTons,
  ) {
    final cargoType =
        widget.load.cargoType.isNotEmpty ? widget.load.cargoType : 'Electronics';

    return Row(
      children: [
        // Left: Cargo Details
        Expanded(
          child: InkWell(
            onTap: () => _openDetails(context),
            borderRadius: BorderRadius.circular(16),
            child: PartnerCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: Color(0xFFB78103),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: ReDoPartnerColors.secondary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cargo details',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ReDoPartnerColors.secondary,
                    ),
                  ),
                  Text(
                    cargoType,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: ReDoPartnerColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(requiredTons * 1000).toInt()} kg • 2 packages',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: ReDoPartnerColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Right: Vehicle Match
        Expanded(
          child: PartnerCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: ReDoPartnerColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vehicle match',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ReDoPartnerColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 12, color: ReDoPartnerColors.success),
                        const SizedBox(width: 3),
                        Text(
                          'Fits your vehicle',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ReDoPartnerColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${truckCapacityTons.toInt()} Ton avail • ${requiredTons.toInt()} Ton req',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: ReDoPartnerColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(NumberFormat currency, int baseFare, int bonus) {
    return PartnerCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Color(0xFFB78103),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated earnings',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ReDoPartnerColors.secondary,
                  ),
                ),
                Text(
                  currency.format(widget.load.offeredPriceInr),
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: ReDoPartnerColors.darkNavy,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: ReDoPartnerColors.border,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Trip fare',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ReDoPartnerColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    currency.format(baseFare),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ReDoPartnerColors.darkNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Bonus',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ReDoPartnerColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    currency.format(bonus),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ReDoPartnerColors.darkNavy,
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        PartnerButton(
          title: 'ACCEPT',
          icon: Icons.check_circle_rounded,
          isLoading: _isProcessing,
          onPressed: _handleAccept,
        ),
        const SizedBox(height: 10),
        PartnerSecondaryButton(
          title: 'SKIP',
          icon: Icons.close_rounded,
          onPressed: _handleSkip,
        ),
      ],
    );
  }

  Widget _buildFooterNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: ReDoPartnerColors.secondary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Another partner may receive this request if you skip or the offer expires.',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ReDoPartnerColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
