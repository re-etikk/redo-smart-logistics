import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import 'shipment_details_screen.dart';

/// Screen 08 — Shipment History
/// Recreated natively in Flutter matching ReDo Design System and reference (media_1791219314741.png).
/// Filters: All, In Transit, Delivered, Cancelled.
/// Search: Real filtering by tracking ID, route, and cargo type.
/// Navigation: Shipment Card -> Shipment Details Screen.
class ShipmentsScreen extends StatefulWidget {
  final VoidCallback? onNewBookingPressed;

  const ShipmentsScreen({
    super.key,
    this.onNewBookingPressed,
  });

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  String _activeTab = 'all'; // 'all', 'in_transit', 'delivered', 'cancelled'
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Canonical reference fallback shipments matching media_1791219314741.png
  // Used only when user has no backend bookings yet so the UI is immediately interactive
  static final List<BookingItem> _referenceShipments = [
    BookingItem(
      id: 'H314315796',
      cargoId: 'H314315796',
      truckId: 'TRK-UP32AB1234',
      origin: 'Delhi, DL',
      destination: 'Patna, BR',
      cargoType: 'Mac Mini M4 Pro',
      weightTons: 0.012, // 12 kg
      agreedPriceInr: 2850,
      status: 'in_transit',
      driverName: 'Rahul Kumar',
      driverPhone: '+91 98765 43210',
      truckReg: 'UP 32 AB 1234',
      createdAt: '2026-10-05T10:20:00Z',
    ),
    BookingItem(
      id: 'H314298765',
      cargoId: 'H314298765',
      truckId: 'TRK-DL01XY5678',
      origin: 'Lucknow, UP',
      destination: 'Delhi, DL',
      cargoType: 'Electronics',
      weightTons: 0.015, // 15 kg
      agreedPriceInr: 1920,
      status: 'delivered',
      driverName: 'Amit Sharma',
      driverPhone: '+91 98111 22334',
      truckReg: 'DL 01 XY 5678',
      createdAt: '2026-09-10T09:15:00Z',
    ),
    BookingItem(
      id: 'H314276543',
      cargoId: 'H314276543',
      truckId: 'TRK-RJ14PQ9012',
      origin: 'Kanpur, UP',
      destination: 'Jaipur, RJ',
      cargoType: 'Packages',
      weightTons: 0.008, // 8 kg
      agreedPriceInr: 2350,
      status: 'delivered',
      driverName: 'Suresh Verma',
      driverPhone: '+91 99222 33445',
      truckReg: 'RJ 14 PQ 9012',
      createdAt: '2026-09-08T11:30:00Z',
    ),
    BookingItem(
      id: 'H314265432',
      cargoId: 'H314265432',
      truckId: 'TRK-UP78LM3456',
      origin: 'Delhi, DL',
      destination: 'Lucknow, UP',
      cargoType: 'Documents',
      weightTons: 0.003, // 3 kg
      agreedPriceInr: 850,
      status: 'cancelled',
      driverName: 'Vikram Singh',
      driverPhone: '+91 97333 44556',
      truckReg: 'UP 78 LM 3456',
      createdAt: '2026-09-05T14:10:00Z',
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ShipmentsViewModel>().fetchShipments(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BookingItem> _getFilteredShipments(List<BookingItem> source) {
    final list = source.isEmpty ? _referenceShipments : source;

    return list.where((b) {
      final st = b.status.toLowerCase();

      // Filter Tab
      if (_activeTab == 'in_transit') {
        if (!['in_transit', 'picked_up', 'confirmed', 'pickup_ready', 'open', 'matching', 'assigned'].contains(st)) {
          return false;
        }
      } else if (_activeTab == 'delivered') {
        if (!['delivered', 'completed'].contains(st)) {
          return false;
        }
      } else if (_activeTab == 'cancelled') {
        if (st != 'cancelled') {
          return false;
        }
      }

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = b.id.toLowerCase().contains(q) || b.cargoId.toLowerCase().contains(q);
        final matchOrigin = b.origin.toLowerCase().contains(q);
        final matchDest = b.destination.toLowerCase().contains(q);
        final matchCargo = b.cargoType.toLowerCase().contains(q);
        if (!matchId && !matchOrigin && !matchDest && !matchCargo) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShipmentsViewModel>();
    final allShipments = vm.shipments.isEmpty ? _referenceShipments : vm.shipments;

    final inTransitCount = allShipments.where((b) {
      final st = b.status.toLowerCase();
      return ['in_transit', 'picked_up', 'confirmed', 'pickup_ready', 'open', 'matching', 'assigned'].contains(st);
    }).length;

    final deliveredCount = allShipments.where((b) {
      final st = b.status.toLowerCase();
      return ['delivered', 'completed'].contains(st);
    }).length;

    final cancelledCount = allShipments.where((b) => b.status.toLowerCase() == 'cancelled').length;

    final displayedItems = _getFilteredShipments(vm.shipments);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : ReDoColors.warmBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: ReDoColors.primaryYellow,
          onRefresh: vm.fetchShipments,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // 1. Header Row: Title & Subtitle + Search action icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your shipments',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track and manage all your deliveries.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Search Input & Filter Icon Box
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search by tracking ID, route or cargo...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkInkMuted : const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 3. Filter Pill Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      id: 'all',
                      label: 'All (${allShipments.length})',
                      isSelected: _activeTab == 'all',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      id: 'in_transit',
                      label: 'In Transit ($inTransitCount)',
                      icon: Icons.local_shipping_rounded,
                      isSelected: _activeTab == 'in_transit',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      id: 'delivered',
                      label: 'Delivered ($deliveredCount)',
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF36A653),
                      isSelected: _activeTab == 'delivered',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      id: 'cancelled',
                      label: 'Cancelled ($cancelledCount)',
                      icon: Icons.cancel_rounded,
                      iconColor: const Color(0xFFE85B5B),
                      isSelected: _activeTab == 'cancelled',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Shipment Cards List
              if (displayedItems.isEmpty)
                _buildEmptyState(isDark: isDark)
              else
                ...displayedItems.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return _buildShipmentCard(index, item, isDark: isDark);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => setState(() => _activeTab = id),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ReDoColors.primaryYellow
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ReDoColors.primaryYellow
                : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? ReDoColors.darkNavy
                    : (iconColor ?? const Color(0xFFD97706)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? ReDoColors.darkNavy
                    : (isDark ? AppColors.darkInk : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentCard(int index, BookingItem b, {required bool isDark}) {
    final status = b.status.toLowerCase();
    final isInTransit = ['in_transit', 'picked_up', 'confirmed', 'pickup_ready'].contains(status);
    final isDelivered = status == 'delivered' || status == 'completed';
    final isCancelled = status == 'cancelled';

    final idCode = b.id.isNotEmpty
        ? (b.id.startsWith('H') ? b.id : 'H${b.id.substring(0, min(9, b.id.length)).toUpperCase()}')
        : 'H314315796';

    final weightText = b.weightTons > 0
        ? (b.weightTons >= 1
            ? '${b.weightTons.toStringAsFixed(1)} tons'
            : '${(b.weightTons * 1000).toStringAsFixed(0)} kg')
        : '12 kg';

    final priceFormatted = b.agreedPriceInr > 0
        ? '₹${NumberFormat('#,##,###').format(b.agreedPriceInr.toInt())}'
        : '₹2,850';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Screen 08 -> Screen 07: Shipment Details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShipmentDetailsScreen(booking: b),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Cargo Thumbnail + Title/ID + Status Badge + Price + Chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cargo Thumbnail Box
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF243041) : const Color(0xFFFFF9EE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFFFECC4)),
                      ),
                      child: Center(
                        child: _buildCargoVectorIcon(b.cargoType),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title, ID, Specs
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$index • $idCode',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkInkMuted : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            b.cargoType.isNotEmpty ? b.cargoType : 'General Cargo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b.cargoType.contains('Mac') ? 'Electronics' : b.cargoType} • $weightText • 2 packages',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Status Chip + Price + Chevron
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusBadge(status),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              priceFormatted,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF243041) : const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkInkMuted : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Route Row with dotted highway and mini truck
                _buildRouteRow(b, isInTransit, isDelivered, isCancelled, isDark: isDark),

                // Bottom Progress Bar if In Transit
                if (isInTransit) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.52,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(ReDoColors.primaryYellow),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '540 km remaining >',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCargoVectorIcon(String cargoType) {
    final lower = cargoType.toLowerCase();
    if (lower.contains('mac') || lower.contains('mini') || lower.contains('electron')) {
      return const _MacMiniSmallGraphic();
    } else if (lower.contains('doc') || lower.contains('paper')) {
      return const Icon(Icons.description_outlined, color: Color(0xFF475569), size: 26);
    } else {
      return const Icon(Icons.inventory_2_outlined, color: Color(0xFFB45309), size: 26);
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    Widget leading;
    String label;

    switch (status) {
      case 'in_transit':
      case 'picked_up':
      case 'confirmed':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        leading = Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF36A653),
            shape: BoxShape.circle,
          ),
        );
        label = 'In Transit';
        break;
      case 'delivered':
      case 'completed':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        leading = const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF36A653));
        label = 'Delivered';
        break;
      case 'cancelled':
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        leading = const Icon(Icons.cancel_rounded, size: 12, color: Color(0xFFE85B5B));
        label = 'Cancelled';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        leading = Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF94A3B8),
            shape: BoxShape.circle,
          ),
        );
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteRow(BookingItem b, bool isInTransit, bool isDelivered, bool isCancelled, {required bool isDark}) {
    Color lineColor;
    if (isInTransit) {
      lineColor = ReDoColors.primaryYellow;
    } else if (isDelivered) {
      lineColor = const Color(0xFF36A653);
    } else {
      lineColor = const Color(0xFFCBD5E1);
    }

    return Row(
      children: [
        // Pickup Pin & City
        Icon(
          Icons.location_on_rounded,
          size: 14,
          color: isInTransit
              ? const Color(0xFFD97706)
              : (isDelivered ? const Color(0xFF36A653) : const Color(0xFF64748B)),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                b.origin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                ),
              ),
              Text(
                '10:20 AM',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9, 
                  color: isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText,
                ),
              ),
            ],
          ),
        ),

        // Route Connector with Mini Truck
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: lineColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: const SizedBox(
                    width: 20,
                    height: 12,
                    child: CustomPaint(
                      painter: _MiniHighwayTruckPainter(),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: lineColor,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 10,
                  color: lineColor,
                ),
              ],
            ),
          ),
        ),

        // Delivery Pin & City
        Icon(
          Icons.location_on_rounded,
          size: 14,
          color: isDelivered
              ? const Color(0xFF36A653)
              : (isCancelled ? const Color(0xFFE85B5B) : const Color(0xFF64748B)),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                b.destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                ),
              ),
              Text(
                isCancelled
                    ? 'Cancelled'
                    : (isDelivered ? '12 Sep 2026' : 'ETA 8:30 PM'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: isCancelled ? FontWeight.w700 : FontWeight.w400,
                  color: isCancelled 
                      ? const Color(0xFFE85B5B) 
                      : (isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2415) : const Color(0xFFFFF9EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 30,
              color: ReDoColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No shipments found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'No shipments match "$_searchQuery".'
                : 'There are no shipments in this category.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MacMiniSmallGraphic extends StatelessWidget {
  const _MacMiniSmallGraphic();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 22,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white70, width: 0.8),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Color(0xFF475569),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _MiniHighwayTruckPainter extends CustomPainter {
  const _MiniHighwayTruckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Small White Cargo Box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.1, w * 0.6, h * 0.7),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.1, w * 0.6, h * 0.7),
        const Radius.circular(2),
      ),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Yellow Cab
    final cab = Path()
      ..moveTo(w * 0.6, h * 0.2)
      ..lineTo(w * 0.9, h * 0.2)
      ..lineTo(w * 0.98, h * 0.45)
      ..lineTo(w * 0.98, h * 0.8)
      ..lineTo(w * 0.6, h * 0.8)
      ..close();
    canvas.drawPath(cab, Paint()..color = ReDoColors.primaryYellow);

    // Wheels
    final wp = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(w * 0.25, h * 0.85), 2.2, wp);
    canvas.drawCircle(Offset(w * 0.8, h * 0.85), 2.2, wp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
