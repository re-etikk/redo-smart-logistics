import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/booking_viewmodel.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../../widgets/redo_design_system.dart';
import 'driver_matching_screen.dart';

/// ReDo Customer App — SCREEN 04: PRICE ESTIMATE
/// Recreated natively in Flutter matching design reference media_1791216697292.png
class PriceEstimateScreen extends StatefulWidget {
  const PriceEstimateScreen({super.key});

  @override
  State<PriceEstimateScreen> createState() => _PriceEstimateScreenState();
}

class _PriceEstimateScreenState extends State<PriceEstimateScreen> {
  bool _isConfirming = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingViewModel>().fetchPriceQuote();
    });
  }

  Future<void> _handleConfirmShipment(double totalFare) async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    final vm = context.read<BookingViewModel>();

    // 1. Create the actual shipment/order record on the backend
    final confirmedCargo = await vm.createShipmentOrder(estimatedPrice: totalFare);

    if (!mounted) return;

    if (confirmedCargo == null) {
      // Backend creation failed or validation failed
      setState(() => _isConfirming = false);
      final error = vm.errorMessage ??
          'Failed to create shipment on REDO servers. Please check your connection and retry.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      // STRICT REQUIREMENT: Do not proceed to driver dispatch until shipment creation is confirmed by the backend!
      return;
    }

    // 2. Refresh customer's active shipments list
    try {
      context.read<ShipmentsViewModel>().fetchShipments();
    } catch (_) {}

    // 3. Search matching trucks for the confirmed cargo
    await vm.searchMatchingTrucks();

    if (!mounted) return;
    setState(() => _isConfirming = false);

    // 4. Show success confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.slateDark, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Shipment #${confirmedCargo.cargoId} created successfully! Finding nearby trucks...',
                style: const TextStyle(
                  color: AppColors.slateDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.brandYellow,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // 5. Only proceed to driver dispatch once confirmed by backend!
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DriverMatchingScreen(),
      ),
    );
  }

  void _handleEditShipment() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();

    final originParts = vm.origin.isNotEmpty ? vm.origin.split(',') : ['Delhi', 'DL'];
    final destParts = vm.destination.isNotEmpty ? vm.destination.split(',') : ['Patna', 'BR'];

    final originCity = originParts.first.trim();
    final originCode = originParts.length > 1 ? originParts[1].trim() : 'DL';

    final destCity = destParts.first.trim();
    final destCode = destParts.length > 1 ? destParts[1].trim() : 'BR';

    final cargoType = vm.cargoType.isNotEmpty ? vm.cargoType : 'Electronics';
    final weightText = '${vm.weightKg.round()} kg';
    final packagesText = '${vm.packageCount}';

    final distanceKm = vm.roadDistanceKm > 0 ? vm.roadDistanceKm.round() : 1050;
    final formattedDistance = NumberFormat('#,##,###').format(distanceKm);

    // Dynamic pricing source of truth from backend
    final isFetching = vm.isFetchingQuote;
    final conditions = vm.pricingConditions;
    final baseFare = vm.priceBaseFareInr > 0 ? vm.priceBaseFareInr : 2200.0;
    final distanceCharge = vm.priceDistanceChargeInr;
    final cargoHandling = vm.priceCargoHandlingInr;
    final serviceFee = vm.priceServiceFeeInr;
    final savingsAmount = vm.savingsAmountInr;
    final savingsPct = vm.savingsPct;
    final totalFare = vm.priceTotalInr > 0 ? vm.priceTotalInr : (baseFare + distanceCharge + cargoHandling + serviceFee);

    return Scaffold(
      backgroundColor: ReDoColors.warmBg,
      appBar: const ReDoAppBar(
        title: 'Price estimate',
        currentStep: 3,
        totalSteps: 4,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Route & Cargo Summary Card
                    _buildRouteAndCargoCard(
                      originCity: originCity,
                      originCode: originCode,
                      destCity: destCity,
                      destCode: destCode,
                      cargoType: cargoType,
                      weightText: weightText,
                      packagesText: packagesText,
                    ),

                    const SizedBox(height: 16),

                    // Hero Estimated Delivery Cost Banner
                    _buildHeroCostBanner(
                      totalFare: totalFare,
                      isFetching: isFetching,
                      savingsAmount: savingsAmount,
                      savingsPct: savingsPct,
                      conditions: conditions,
                      originCity: originCity,
                    ),

                    const SizedBox(height: 20),

                    // Price Breakdown Card
                    _buildPriceBreakdownCard(
                      baseFare: baseFare,
                      distanceKm: formattedDistance,
                      distanceCharge: distanceCharge,
                      cargoHandling: cargoHandling,
                      serviceFee: serviceFee,
                      totalFare: totalFare,
                      savingsAmount: savingsAmount,
                      savingsPct: savingsPct,
                      conditions: conditions,
                    ),

                    const SizedBox(height: 16),

                    // Pricing Conditions Card
                    _buildPricingConditionsCard(
                      conditions: conditions,
                      actualWeightKg: vm.weightKg,
                      billableWeightKg: vm.billableWeightTons * 1000,
                    ),

                    const SizedBox(height: 16),

                    // Estimated Delivery Time Card
                    _buildEstimatedDeliveryCard(
                      distanceText: formattedDistance,
                      originCity: originCity,
                      destCity: destCity,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom CTA Bar with Confirm button and "Edit shipment"
            _buildBottomCtaBar(totalFare),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Top Card: Route Schematic + Cargo Summary
  // --------------------------------------------------------------------------
  Widget _buildRouteAndCargoCard({
    required String originCity,
    required String originCode,
    required String destCity,
    required String destCode,
    required String cargoType,
    required String weightText,
    required String packagesText,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Upper Section: Origin -> Moving Truck -> Destination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Origin Pin & City
                Flexible(
                  flex: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFECC4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: Color(0xFFD98800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              originCity,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: ReDoColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              originCode,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: ReDoColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Middle: Curved Dashed Line with ReDo Truck
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: SizedBox(
                      height: 40,
                      child: CustomPaint(
                        painter: _RouteTruckSchematicPainter(),
                      ),
                    ),
                  ),
                ),

                // Destination Pin & City
                Flexible(
                  flex: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFECC4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: Color(0xFFD98800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destCity,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: ReDoColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              destCode,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: ReDoColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

          // Divider
          Container(
            height: 1,
            color: const Color(0xFFF1ECE1),
          ),

          // Lower Section: 3-column Cargo Summary Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Cargo',
                    value: cargoType,
                  ),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFF1ECE1)),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.scale_rounded,
                    label: 'Weight',
                    value: weightText,
                  ),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFF1ECE1)),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.all_inbox_rounded,
                    label: 'Packages',
                    value: packagesText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F2E9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 16, color: ReDoColors.darkNavy),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: ReDoColors.secondaryText,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ReDoColors.darkNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Hero Cost Banner with Native Truck Illustration
  // --------------------------------------------------------------------------
  Widget _buildHeroCostBanner({
    required double totalFare,
    required bool isFetching,
    required double savingsAmount,
    required int savingsPct,
    PricingConditions? conditions,
    required String originCity,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF8),
            Color(0xFFFFECC4),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFDF9E),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE59C0A).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  // Left: Price Info
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Estimated delivery cost',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B5838),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isFetching) ...[
                              const SizedBox(width: 6),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFD98800),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currencyFormat.format(totalFare.round()),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: ReDoColors.darkNavy,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (savingsPct > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD5F5E3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.savings_outlined, size: 13, color: Color(0xFF27AE60)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Save ${_currencyFormat.format(savingsAmount.round())} ($savingsPct%) vs full truckload',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E8449),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          conditions?.isSurging == true
                              ? 'Includes surge (${conditions!.surgeMultiplier.toStringAsFixed(2)}x) due to high demand in $originCity.'
                              : 'Real backend quote calculated from verified return trip capacity.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7A6B53),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: 100% Native Vector Truck Illustration
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 110,
                      child: CustomPaint(
                        painter: _HeroTruckHighwayVectorPainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Price Breakdown Card
  // --------------------------------------------------------------------------
  Widget _buildPriceBreakdownCard({
    required double baseFare,
    required String distanceKm,
    required double distanceCharge,
    required double cargoHandling,
    required double serviceFee,
    required double totalFare,
    required double savingsAmount,
    required int savingsPct,
    PricingConditions? conditions,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ReDoColors.darkNavy,
            ),
          ),
          const SizedBox(height: 16),

          _buildBreakdownRow(
            icon: Icons.local_shipping_outlined,
            label: 'Driver freight (Base)',
            amount: _currencyFormat.format(baseFare.round()),
            subtitle: conditions != null ? 'Lane: ${conditions.corridorName}' : null,
          ),
          if (distanceCharge > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              icon: Icons.route_outlined,
              label: 'Distance ($distanceKm km)',
              amount: _currencyFormat.format(distanceCharge.round()),
            ),
          ],
          if (cargoHandling > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              icon: Icons.inventory_2_outlined,
              label: 'Special cargo handling',
              amount: _currencyFormat.format(cargoHandling.round()),
            ),
          ],
          const SizedBox(height: 12),
          _buildBreakdownRow(
            icon: Icons.description_outlined,
            label: 'ReDo platform fee (8%)',
            amount: _currencyFormat.format(serviceFee.round()),
            subtitle: 'Secure escrow & digital e-waybill',
          ),

          if (savingsAmount > 0) ...[
            const SizedBox(height: 12),
            _buildBreakdownRow(
              icon: Icons.savings_outlined,
              label: 'Backhaul capacity credit',
              amount: '-${_currencyFormat.format(savingsAmount.round())}',
              isGreen: true,
              subtitle: '$savingsPct% cheaper than dedicated full truck',
            ),
          ],

          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF1ECE1)),
          const SizedBox(height: 14),

          // Total Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECC4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: Color(0xFFD98800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final price (INR)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ReDoColors.darkNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'All taxes & platform fees included',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ReDoColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _currencyFormat.format(totalFare.round()),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ReDoColors.darkNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required IconData icon,
    required String label,
    required String amount,
    String? subtitle,
    bool isGreen = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isGreen ? const Color(0xFFD5F5E3) : const Color(0xFFF6F2E9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: isGreen ? const Color(0xFF27AE60) : ReDoColors.darkNavy,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isGreen ? const Color(0xFF1E8449) : const Color(0xFF4A5568),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isGreen ? const Color(0xFF27AE60) : ReDoColors.secondaryText,
                  ),
                ),
            ],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isGreen ? const Color(0xFF27AE60) : ReDoColors.darkNavy,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Pricing Conditions Card
  // --------------------------------------------------------------------------
  Widget _buildPricingConditionsCard({
    PricingConditions? conditions,
    required double actualWeightKg,
    required double billableWeightKg,
  }) {
    final isSurging = conditions?.isSurging ?? false;
    final surgeMult = conditions?.surgeMultiplier ?? 1.0;
    final ratePerTonKm = conditions?.baseRatePerTonKm ?? 2.50;
    final corridorName = conditions?.corridorName ?? 'All-India Standard Lane';
    final urgency = conditions?.urgency ?? 'standard';
    final supplyCount = conditions?.supplyCount ?? 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Pricing conditions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: ReDoColors.secondaryText,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Two Conditions Tiles
          Row(
            children: [
              // Demand / Surge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F2E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSurging ? const Color(0xFFFFECC4) : const Color(0xFFD5F5E3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.bar_chart_rounded,
                            size: 16,
                            color: isSurging ? const Color(0xFFD98800) : const Color(0xFF27AE60),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Market Demand',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: ReDoColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isSurging ? 'Surge ${surgeMult.toStringAsFixed(2)}x' : 'Balanced (1.0x)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSurging ? const Color(0xFFD98800) : ReDoColors.darkNavy,
                              ),
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

              const SizedBox(width: 8),

              // Vehicle availability
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F2E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD5F5E3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF27AE60)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Availability',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: ReDoColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              supplyCount > 0 ? '$supplyCount trucks active' : 'Available',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ReDoColors.darkNavy,
                              ),
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
            ],
          ),

          const SizedBox(height: 14),

          // Conditions breakdown strip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildConditionItem(
                  label: 'Rate per ton-km',
                  value: '₹${ratePerTonKm.toStringAsFixed(2)} / ton-km',
                ),
                const SizedBox(height: 6),
                _buildConditionItem(
                  label: 'Billable weight',
                  value: '${billableWeightKg.round()} kg (Actual: ${actualWeightKg.round()} kg)',
                ),
                const SizedBox(height: 6),
                _buildConditionItem(
                  label: 'Dispatch urgency',
                  value: urgency == 'express' ? '⚡ Express Priority' : 'Standard Delivery',
                ),
                const SizedBox(height: 6),
                _buildConditionItem(
                  label: 'Corridor lane',
                  value: corridorName,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Text(
            'Rates dynamically synchronized with the ReDo pricing engine. No hidden charges at pickup.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: ReDoColors.secondaryText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: ReDoColors.secondaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ReDoColors.darkNavy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Estimated Delivery Card
  // --------------------------------------------------------------------------
  Widget _buildEstimatedDeliveryCard({
    required String distanceText,
    required String originCity,
    required String destCity,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReDoColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Clock & Delivery Time
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECC4),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.access_time_rounded,
                size: 20,
                color: Color(0xFFD98800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Today, 8:30 PM',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ReDoColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Approx. $distanceText km',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ReDoColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Mini route schematic
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 44,
              child: CustomPaint(
                painter: _DeliverySchematicPainter(
                  originName: originCity,
                  destName: destCity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom CTA Bar
  // --------------------------------------------------------------------------
  Widget _buildBottomCtaBar(double totalFare) {
    return Container(
      decoration: BoxDecoration(
        color: ReDoColors.warmBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReDoButton(
            text: 'Confirm shipment',
            showArrow: true,
            isLoading: _isConfirming,
            onPressed: () => _handleConfirmShipment(totalFare),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _handleEditShipment,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Edit shipment',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5A626C),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Custom Vector Painters (Zero Screenshots, 100% Native Vector Drawing)
// ----------------------------------------------------------------------------

class _RouteTruckSchematicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.1,
        size.width,
        size.height * 0.7,
      );

    final dashPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw dashed bezier
    final metrics = path.computeMetrics().first;
    const dashLength = 5.0;
    const dashGap = 4.0;
    double distance = 0.0;
    while (distance < metrics.length) {
      final extractPath = metrics.extractPath(distance, distance + dashLength);
      canvas.drawPath(extractPath, dashPaint);
      distance += dashLength + dashGap;
    }

    // Draw small mini truck in the center
    final truckCenter = metrics.getTangentForOffset(metrics.length * 0.5)?.position ??
        Offset(size.width * 0.5, size.height * 0.35);

    final cabinPaint = Paint()..color = const Color(0xFFFFB21A);
    final trailerPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Trailer
    final trailerRect = Rect.fromCenter(
      center: Offset(truckCenter.dx - 8, truckCenter.dy - 6),
      width: 22,
      height: 12,
    );
    canvas.drawRect(trailerRect, trailerPaint);
    canvas.drawRect(trailerRect, borderPaint);

    // Cabin
    final cabinRect = Rect.fromCenter(
      center: Offset(truckCenter.dx + 8, truckCenter.dy - 5),
      width: 10,
      height: 10,
    );
    canvas.drawRect(cabinRect, cabinPaint);
    canvas.drawRect(cabinRect, borderPaint);

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF222222);
    canvas.drawCircle(Offset(truckCenter.dx - 14, truckCenter.dy + 1), 2.5, wheelPaint);
    canvas.drawCircle(Offset(truckCenter.dx - 3, truckCenter.dy + 1), 2.5, wheelPaint);
    canvas.drawCircle(Offset(truckCenter.dx + 8, truckCenter.dy + 1), 2.5, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroTruckHighwayVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // City Skyline & Bridge Silhouette
    final bridgePaint = Paint()
      ..color = const Color(0xFFE2C99F).withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final bridgeFill = Paint()
      ..color = const Color(0xFFEAD5B0).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Bridge arches
    final bridgePath = Path()
      ..moveTo(size.width * 0.05, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.4, size.width * 0.5, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.4, size.width * 0.05, size.height * 0.5)
      ..close();
    canvas.drawPath(bridgePath, bridgeFill);
    canvas.drawPath(bridgePath, bridgePaint);

    // Cable stays
    canvas.drawLine(Offset(size.width * 0.25, size.height * 0.35), Offset(size.width * 0.05, size.height * 0.7), bridgePaint);
    canvas.drawLine(Offset(size.width * 0.25, size.height * 0.35), Offset(size.width * 0.45, size.height * 0.7), bridgePaint);

    // Modern Asphalt Road
    final roadPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.95)
      ..lineTo(size.width * 0.95, size.height * 0.75)
      ..lineTo(size.width * 0.95, size.height * 0.85)
      ..lineTo(size.width * 0.1, size.height)
      ..close();
    final roadPaint = Paint()..color = const Color(0xFF4A5568);
    canvas.drawPath(roadPath, roadPaint);

    // ReDo Freight Truck Body (White Trailer + Yellow Cabin)
    // 1. Trailer
    final trailerPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.45)
      ..lineTo(size.width * 0.88, size.height * 0.38)
      ..lineTo(size.width * 0.85, size.height * 0.7)
      ..lineTo(size.width * 0.32, size.height * 0.75)
      ..close();
    final trailerPaint = Paint()..color = Colors.white;
    canvas.drawPath(trailerPath, trailerPaint);

    final trailerBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(trailerPath, trailerBorder);

    // ReDo Branding on Trailer
    final logoTextPainter = TextPainter(
      text: TextSpan(
        text: 'ReDo',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1E293B),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    logoTextPainter.paint(canvas, Offset(size.width * 0.52, size.height * 0.5));

    // 2. Yellow Cabin
    final cabinPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.6)
      ..lineTo(size.width * 0.33, size.height * 0.55)
      ..lineTo(size.width * 0.32, size.height * 0.82)
      ..lineTo(size.width * 0.15, size.height * 0.85)
      ..close();
    final cabinPaint = Paint()..color = const Color(0xFFFFB21A);
    canvas.drawPath(cabinPath, cabinPaint);

    // Windshield
    final windshieldPath = Path()
      ..moveTo(size.width * 0.17, size.height * 0.62)
      ..lineTo(size.width * 0.31, size.height * 0.58)
      ..lineTo(size.width * 0.30, size.height * 0.68)
      ..lineTo(size.width * 0.17, size.height * 0.70)
      ..close();
    final windshieldPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawPath(windshieldPath, windshieldPaint);

    // Headlight
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.78), 3, Paint()..color = const Color(0xFFFFF3C4));

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF1E293B);
    final rimPaint = Paint()..color = const Color(0xFF94A3B8);

    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.86), 6.5, wheelPaint);
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.86), 2.5, rimPaint);

    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.82), 6.5, wheelPaint);
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.82), 2.5, rimPaint);

    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.74), 6.5, wheelPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.74), 2.5, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeliverySchematicPainter extends CustomPainter {
  final String originName;
  final String destName;

  _DeliverySchematicPainter({
    required this.originName,
    required this.destName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFFFB21A)
      ..strokeWidth = 2.0;

    final y = size.height * 0.5;
    canvas.drawLine(Offset(size.width * 0.1, y), Offset(size.width * 0.9, y), linePaint);

    // Origin pin
    final pinPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(size.width * 0.1, y), 4, pinPaint);

    // Dest pin
    canvas.drawCircle(Offset(size.width * 0.9, y), 4, pinPaint);

    // Mini truck in the center
    final truckRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, y - 4),
      width: 18,
      height: 9,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(truckRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFFFB21A),
    );

    // Origin text below
    final originPainter = TextPainter(
      text: TextSpan(
        text: originName,
        style: GoogleFonts.inter(fontSize: 9, color: ReDoColors.secondaryText, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    originPainter.paint(canvas, Offset(size.width * 0.05, y + 8));

    // Dest text below
    final destPainter = TextPainter(
      text: TextSpan(
        text: destName,
        style: GoogleFonts.inter(fontSize: 9, color: ReDoColors.secondaryText, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    destPainter.paint(canvas, Offset(size.width * 0.95 - destPainter.width, y + 8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
