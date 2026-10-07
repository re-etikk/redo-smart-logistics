import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/redo_partner_components.dart';

/// Screen 03 — Request Details
/// Recreates the full details screen for a dispatch trip request matching Reference 03.
/// Connects to real trip/request data and accept/skip flows.
class RequestDetailsScreen extends StatefulWidget {
  final AvailableLoad load;
  final int? secondsRemaining;
  final Future<void> Function() onAccept;
  final VoidCallback onDecline;

  const RequestDetailsScreen({
    super.key,
    required this.load,
    this.secondsRemaining,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
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
      if (mounted) {
        Navigator.of(context).pop();
      }
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
    Navigator.of(context).pop();
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

    final origin = widget.load.origin.isNotEmpty ? widget.load.origin : 'Delhi, DL';
    final destination = widget.load.destination.isNotEmpty ? widget.load.destination : 'Patna, BR';
    final distanceText = widget.load.distanceKm > 0
        ? '${widget.load.distanceKm.round()} km'
        : '1,000 km';

    return Scaffold(
      backgroundColor: ReDoPartnerColors.warmBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: ReDoPartnerColors.warmBg,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: ReDoPartnerColors.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: ReDoPartnerColors.darkNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Trip details',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ReDoPartnerColors.darkNavy,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ReDoPartnerColors.brandYellow.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'New request',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE65100),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. Route Map Card
          PartnerCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  origin.split(',').first.trim(),
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
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
                                size: 18,
                                color: ReDoPartnerColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  destination.split(',').first.trim(),
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
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
                          Row(
                            children: [
                              const Icon(Icons.alt_route_rounded,
                                  size: 13, color: Color(0xFFFF9800)),
                              const SizedBox(width: 4),
                              Text(
                                distanceText,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ReDoPartnerColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '•',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: ReDoPartnerColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Long haul',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ReDoPartnerColors.border),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        size: 20,
                        color: ReDoPartnerColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 180,
                    child: MapPanel(
                      originName: origin,
                      destName: destination,
                      height: 180,
                      showControls: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Pickup & Delivery Window Card
          PartnerCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pickup row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFE65100),
                        size: 20,
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
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                          Text(
                            origin,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                          Text(
                            '10 km from you',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 13, color: ReDoPartnerColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'Pickup window',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: ReDoPartnerColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.load.pickupWindow.isNotEmpty
                              ? widget.load.pickupWindow
                              : '10:30 AM – 11:00 AM',
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

                // Dotted connector
                Padding(
                  padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB21A),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Delivery row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ReDoPartnerColors.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: ReDoPartnerColors.darkNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                          Text(
                            destination,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 13, color: ReDoPartnerColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'Estimated delivery',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: ReDoPartnerColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Today, 8:30 PM',
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
          ),
          const SizedBox(height: 12),

          // 3. Two-Column Cards: Cargo Details & Vehicle Requirement
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Cargo Details
              Expanded(
                child: PartnerCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cargo details',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: ReDoPartnerColors.darkNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.load.cargoType.isNotEmpty
                            ? widget.load.cargoType
                            : 'Electronics',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: ReDoPartnerColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 13, color: ReDoPartnerColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${(requiredTons * 1000).toInt()} kg',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 13, color: ReDoPartnerColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '2 packages',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wine_bar_rounded,
                                size: 14, color: Color(0xFFD32F2F)),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Special handling',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: const Color(0xFFD32F2F),
                                  ),
                                ),
                                Text(
                                  'Fragile',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFD32F2F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Right: Vehicle Requirement
              Expanded(
                child: PartnerCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vehicle req',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: ReDoPartnerColors.darkNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your vehicle',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                          Text(
                            '${truckCapacityTons.toInt()} Ton capacity',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Required',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                          Text(
                            '${requiredTons.toInt()} Ton',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ReDoPartnerColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: fitsVehicle ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              fitsVehicle ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                              size: 14,
                              color: fitsVehicle ? ReDoPartnerColors.success : ReDoPartnerColors.danger,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fitsVehicle ? 'Vehicle compatible' : 'Capacity check required',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: fitsVehicle ? ReDoPartnerColors.success : ReDoPartnerColors.danger,
                                    ),
                                  ),
                                  Text(
                                    fitsVehicle
                                        ? 'Your vehicle can carry this load.'
                                        : 'Load weight exceeds nominal capacity.',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: fitsVehicle ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Earnings Estimate Card
          PartnerCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 20,
                            color: Color(0xFFB78103),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Earnings estimate',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: ReDoPartnerColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              size: 14, color: Color(0xFFB78103)),
                          const SizedBox(width: 4),
                          Text(
                            'Good opportunity',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB78103),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currency.format(widget.load.offeredPriceInr),
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: ReDoPartnerColors.darkNavy,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            'estimated',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ReDoPartnerColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: ReDoPartnerColors.border,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Base trip',
                                  style: GoogleFonts.inter(fontSize: 11, color: ReDoPartnerColors.secondary)),
                              Text(currency.format(baseFare),
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Bonus',
                                  style: GoogleFonts.inter(fontSize: 11, color: ReDoPartnerColors.secondary)),
                              Text(currency.format(bonus),
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900)),
                              Text(
                                currency.format(widget.load.offeredPriceInr),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: ReDoPartnerColors.darkNavy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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

          // 5. Action Buttons: Accept Trip & Skip
          PartnerButton(
            title: 'Accept Trip',
            icon: Icons.check_circle_rounded,
            isLoading: _isProcessing,
            onPressed: _handleAccept,
          ),
          const SizedBox(height: 10),
          PartnerSecondaryButton(
            title: 'Skip',
            icon: Icons.close_rounded,
            onPressed: _handleSkip,
          ),
          const SizedBox(height: 12),

          // Footer note
          Row(
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
          ),
        ],
      ),
    );
  }
}
