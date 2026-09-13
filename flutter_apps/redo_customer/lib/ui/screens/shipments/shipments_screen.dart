import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_strings.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../misc/notifications_screen.dart';
import 'tracking_screen.dart';

class ShipmentsScreen extends StatefulWidget {
  final VoidCallback? onNewBookingPressed;
  const ShipmentsScreen({super.key, this.onNewBookingPressed});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  String _filter = 'all'; // all, ongoing, completed, cancelled
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'newest'; // newest, oldest, weight_high, weight_low

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

  void _showFilterModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context, 'filters'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slateDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sort by',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSortChip('Newest First', 'newest', isDark, setSheetState),
                      _buildSortChip('Oldest First', 'oldest', isDark, setSheetState),
                      _buildSortChip('Heaviest (Tons)', 'weight_high', isDark, setSheetState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandYellow,
                        foregroundColor: AppColors.slateDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(String label, String value, bool isDark, StateSetter setSheetState) {
    final isSelected = _sortOption == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.brandYellow,
      backgroundColor: isDark ? AppColors.darkCanvas : const Color(0xFFF1F5F9),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? AppColors.slateDark : (isDark ? Colors.white70 : AppColors.inkMuted),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.brandYellow : (isDark ? AppColors.darkBorder : AppColors.border),
      ),
      onSelected: (_) {
        setSheetState(() => _sortOption = value);
        setState(() => _sortOption = value);
      },
    );
  }

  List<BookingItem> _filterAndSort(List<BookingItem> all) {
    final list = all.where((b) {
      final st = b.status.toLowerCase();
      if (_filter == 'ongoing') {
        if (!['in_transit', 'picked_up', 'confirmed', 'pickup_ready', 'open', 'searching', 'pending', 'assigned'].contains(st)) {
          return false;
        }
      } else if (_filter == 'completed') {
        if (!['completed', 'delivered'].contains(st)) return false;
      } else if (_filter == 'cancelled') {
        if (st != 'cancelled') return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = b.id.toLowerCase().contains(q);
        final matchOrigin = b.origin.toLowerCase().contains(q);
        final matchDest = b.destination.toLowerCase().contains(q);
        final matchCargo = b.cargoType.toLowerCase().contains(q);
        if (!matchId && !matchOrigin && !matchDest && !matchCargo) return false;
      }

      return true;
    }).toList();

    if (_sortOption == 'newest') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortOption == 'oldest') {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortOption == 'weight_high') {
      list.sort((a, b) => b.weightTons.compareTo(a.weightTons));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShipmentsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allCount = vm.shipments.length;
    final ongoingCount = vm.shipments.where((b) {
      final st = b.status.toLowerCase();
      return ['in_transit', 'picked_up', 'confirmed', 'pickup_ready', 'open', 'searching', 'pending', 'assigned'].contains(st);
    }).length;
    final completedCount = vm.shipments.where((b) {
      final st = b.status.toLowerCase();
      return ['completed', 'delivered'].contains(st);
    }).length;
    final cancelledCount = vm.shipments.where((b) => b.status.toLowerCase() == 'cancelled').length;

    final items = _filterAndSort(vm.shipments);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
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
                onRefresh: vm.fetchShipments,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                  children: [
                    // Screen Title Row + "+ New Booking" Button
                    _buildHeaderRow(isDark),
                    const SizedBox(height: 14),

                    // Filter Tabs Row (All, Ongoing, Completed, Cancelled)
                    _buildFilterTabs(
                      isDark: isDark,
                      allCount: allCount,
                      ongoingCount: ongoingCount,
                      completedCount: completedCount,
                      cancelledCount: cancelledCount,
                    ),
                    const SizedBox(height: 12),

                    // Search and Filters Button Row
                    _buildSearchAndFilterRow(isDark),
                    const SizedBox(height: 14),

                    // List of Shipment Cards
                    if (vm.isLoading) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: AppColors.brandYellow),
                        ),
                      ),
                    ] else if (items.isEmpty) ...[
                      _buildEmptyState(isDark),
                    ] else ...[
                      ...items.map((b) => _buildBookingCard(b, isDark)),
                    ],

                    const SizedBox(height: 8),

                    // Bottom "Need to move another load?" Banner
                    _buildNeedAnotherLoadBanner(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.of(context, 'myBookings'),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slateDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.of(context, 'manageShipments'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: widget.onNewBookingPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandYellow,
            foregroundColor: AppColors.slateDark,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: AppColors.slateDark),
              const SizedBox(width: 4),
              Text(
                'New Booking',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slateDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs({
    required bool isDark,
    required int allCount,
    required int ongoingCount,
    required int completedCount,
    required int cancelledCount,
  }) {
    final tabs = [
      ('All', 'all', allCount),
      ('Ongoing', 'ongoing', ongoingCount),
      ('Completed', 'completed', completedCount),
      ('Cancelled', 'cancelled', cancelledCount),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _filter == tab.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _filter = tab.$2),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandYellow
                      : (isDark ? AppColors.darkCard : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandYellow
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.$1,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.slateDark
                            : (isDark ? Colors.white70 : AppColors.inkMuted),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${tab.$3}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.slateDark
                              : (isDark ? Colors.white70 : AppColors.inkMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilterRow(bool isDark) {
    return Row(
      children: [
        // Search Input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.inkMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white : AppColors.slateDark,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.of(context, 'searchBookingsHint'),
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.darkInkMuted : AppColors.inkFaint,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: AppColors.inkMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Filters Button
        InkWell(
          onTap: () => _showFilterModal(context, isDark),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: isDark ? Colors.white70 : AppColors.slateDark,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.of(context, 'filters'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slateDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BookingItem b, bool isDark) {
    final st = b.status.toLowerCase();
    final isOngoing = ['in_transit', 'picked_up', 'confirmed', 'pickup_ready'].contains(st);
    final idDisplay = b.id.length > 9 ? b.id.substring(0, 9).toUpperCase() : b.id.toUpperCase();
    final dateStr = _formatBookingDate(b.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TrackingScreen(booking: b)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Card Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Redo Yellow Commercial Truck Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/tracking_truck_thumb.png',
                      width: 52,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        width: 52,
                        height: 40,
                        color: const Color(0xFFFEF3C7),
                        child: const Icon(
                          Icons.local_shipping,
                          color: AppColors.brandYellow,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Route and specs
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#$idDisplay',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${b.origin} → ${b.destination}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.slateDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${b.weightTons.toStringAsFixed(1)} T • ${b.cargoType.isNotEmpty ? b.cargoType : 'Parcel / Express'}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date, Status Badge & Chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.inkFaint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusBadge(b.status, isDark),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.inkFaint,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Mini-Stepper if active / in_transit (Matching Card 1 in screenshot!)
              if (isOngoing) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: _buildMiniStepper(b, isDark),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStepper(BookingItem b, bool isDark) {
    final st = b.status.toLowerCase();
    final createdDate = DateTime.tryParse(b.createdAt) ?? DateTime.now();

    final step1Time = DateFormat('d MMM, HH:mm').format(createdDate);
    final step2Time = DateFormat('d MMM, HH:mm').format(createdDate.add(const Duration(hours: 6)));

    final isBookedDone = true;
    final isPickedUpDone = ['picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'completed'].contains(st);
    final isInTransitCurrent = st == 'in_transit';

    final steps = [
      {'title': 'Booked', 'subtitle': step1Time, 'done': isBookedDone, 'current': false},
      {'title': 'Picked Up', 'subtitle': step2Time, 'done': isPickedUpDone, 'current': false},
      {'title': 'In Transit', 'subtitle': '', 'done': false, 'current': isInTransitCurrent},
      {'title': 'Delivered', 'subtitle': '', 'done': false, 'current': false},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final done = step['done'] as bool;
        final current = step['current'] as bool;
        final isLast = i == steps.length - 1;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i == 0
                          ? Colors.transparent
                          : (done || current ? AppColors.brandYellow : (isDark ? AppColors.darkBorder : AppColors.border)),
                    ),
                  ),
                  if (done)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.brandYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 10, color: AppColors.slateDark),
                    )
                  else if (current)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.brandYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_shipping, size: 9, color: AppColors.slateDark),
                    )
                  else
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white38 : AppColors.inkFaint,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isLast
                          ? Colors.transparent
                          : (done ? AppColors.brandYellow : (isDark ? AppColors.darkBorder : AppColors.border)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                step['title'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: done || current ? FontWeight.w800 : FontWeight.w500,
                  color: done || current
                      ? (isDark ? Colors.white : AppColors.slateDark)
                      : AppColors.inkFaint,
                ),
              ),
              if ((step['subtitle'] as String).isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  step['subtitle'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color bg;
    Color fg;
    String text;

    switch (status.toLowerCase()) {
      case 'in_transit':
        bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
        fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D);
        text = 'In Transit';
        break;
      case 'picked_up':
        bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
        fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D);
        text = 'Picked Up';
        break;
      case 'confirmed':
      case 'assigned':
        bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
        fg = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
        text = 'Confirmed';
        break;
      case 'completed':
      case 'delivered':
        bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
        fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D);
        text = 'Completed';
        break;
      case 'cancelled':
        bg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
        fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
        text = 'Cancelled';
        break;
      default:
        bg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706);
        text = 'Open';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildNeedAnotherLoadBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.of(context, 'needToMoveLoad'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slateDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.of(context, 'instantMatches'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: widget.onNewBookingPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Book Again',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward, size: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/tracking_parcel_box.png',
              width: 38,
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.inventory_2,
                color: Color(0xFFD97706),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: AppColors.slateDark,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.of(context, 'noBookingsFound'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slateDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No shipments match your current filter or search. Create a new booking to get started.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onNewBookingPressed,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Book a Truck Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBookingDate(String raw) {
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return 'Recent';
    return DateFormat('d MMM yyyy, hh:mm a').format(dt);
  }
}
