import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/booking_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ShipmentsViewModel>().fetchShipments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShipmentsViewModel>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final filteredItems = vm.shipments.where((item) {
      // 1. Tab status filter
      if (_filter == 'ongoing') {
        if (['completed', 'cancelled'].contains(item.status)) return false;
      } else if (_filter == 'completed') {
        if (!['completed', 'delivered'].contains(item.status)) return false;
      } else if (_filter == 'cancelled') {
        if (item.status != 'cancelled') return false;
      }

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesRoute = item.origin.toLowerCase().contains(q) ||
            item.destination.toLowerCase().contains(q);
        final matchesId = item.id.toLowerCase().contains(q);
        final matchesCargo = item.cargoType.toLowerCase().contains(q);
        if (!matchesRoute && !matchesId && !matchesCargo) return false;
      }
      return true;
    }).toList();

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

            // Top Header: Title + "+ New Booking" Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Bookings',
                          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track shipments and manage return loads.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onNewBookingPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: AppColors.slateDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'New Booking',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Tabs (All, Ongoing, Completed, Cancelled)
            _buildFilterTabs(),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by city, cargo or Booking ID...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),

            // Bookings List / Empty State
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandYellow,
                onRefresh: vm.fetchShipments,
                child: _buildBookingsContent(vm, filteredItems, currency),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      ('All', 'all'),
      ('Ongoing', 'ongoing'),
      ('Completed', 'completed'),
      ('Cancelled', 'cancelled'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _filter == tab.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tab.$1),
              selected: isSelected,
              selectedColor: AppColors.brandYellow,
              backgroundColor: Theme.of(context).cardColor,
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.slateDark : AppColors.inkMuted,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.brandYellow : AppColors.border,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) => setState(() => _filter = tab.$2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingsContent(
    ShipmentsViewModel vm,
    List<BookingItem> items,
    NumberFormat currency,
  ) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.inkMuted),
                const SizedBox(height: 12),
                Text(
                  'Could not load bookings',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  vm.errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: vm.fetchShipments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.inkMuted),
                const SizedBox(height: 14),
                Text(
                  _filter == 'all' ? 'No bookings found' : 'No $_filter bookings',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No shipments match "$_searchQuery". Try clearing search.'
                      : 'Book your cargo to see live shipment cards and tracking updates here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: widget.onNewBookingPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandYellow,
                    foregroundColor: AppColors.slateDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.search),
                  label: Text(
                    'Book Transport',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) => _buildShipmentCard(items[index], currency),
    );
  }

  Widget _buildShipmentCard(BookingItem item, NumberFormat currency) {
    final shortId = item.id.length > 8 ? item.id.substring(0, 8).toUpperCase() : item.id.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Booking ID + Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_outlined, size: 14, color: AppColors.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      '#REDO-$shortId',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slateDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 12),

          // Route: Origin -> Destination
          Row(
            children: [
              const Icon(Icons.trip_origin, color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.origin,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 14, color: AppColors.inkMuted),
              ),
              const Icon(Icons.location_on, color: AppColors.danger, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.destination,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Cargo Info Chip
          Text(
            '${item.weightTons.toStringAsFixed(1)} Tons · ${item.cargoType.isEmpty ? 'Cargo' : item.cargoType}',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 14),

          // 4-Step Stepper from Mockup 2
          _build4StepStepper(item.status),
          const SizedBox(height: 14),

          const Divider(height: 1),
          const SizedBox(height: 12),

          // Bottom Row: Price + Action Buttons
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agreed Price',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted),
                  ),
                  Text(
                    currency.format(item.agreedPriceInr),
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const Spacer(),
              _buildActions(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build4StepStepper(String status) {
    const steps = [
      'Order Placed',
      'Driver Assigned',
      'In Transit',
      'Delivered',
    ];

    int currentStep = 0;
    if (['pending', 'requested'].contains(status)) {
      currentStep = 0;
    } else if (['accepted', 'confirmed', 'pickup_ready'].contains(status)) {
      currentStep = 1;
    } else if (['picked_up', 'in_transit'].contains(status)) {
      currentStep = 2;
    } else if (['delivered', 'completed'].contains(status)) {
      currentStep = 3;
    }

    return Row(
      children: List.generate(steps.length, (i) {
        final isDone = i <= currentStep;
        final isLast = i == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.brandYellow : AppColors.canvas,
                      border: Border.all(
                        color: isDone ? AppColors.brandYellow : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 12, color: AppColors.slateDark)
                          : Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.inkFaint,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
                      color: isDone ? AppColors.slateDark : AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: i < currentStep ? AppColors.brandYellow : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActions(BookingItem item) {
    final vm = context.read<ShipmentsViewModel>();
    final canConfirm = item.status == 'accepted';
    final canComplete = item.status == 'delivered';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Track Button
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TrackingScreen(booking: item)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: AppColors.slateDark,
            elevation: 0,
            side: BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.location_searching, size: 14),
          label: Text('Track', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
        ),

        // Confirm Button
        if (canConfirm) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final error = await vm.confirmBooking(item);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error ?? 'Booking confirmed successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('Confirm', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],

        // Complete & Rate Button
        if (canComplete) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final error = await vm.completeBooking(item);
              if (!mounted) return;
              if (error == null) {
                _rateDialog(item);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('Complete', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],

        // Rebook Button (for completed)
        if (item.status == 'completed') ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _rateDialog(item),
            icon: const Icon(Icons.star_outline, size: 20, color: AppColors.brandYellow),
            tooltip: 'Rate driver',
          ),
          OutlinedButton(
            onPressed: () {
              final bvm = context.read<BookingViewModel>();
              bvm.setOrigin(item.origin);
              bvm.setDestination(item.destination);
              widget.onNewBookingPressed?.call();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: Text('Rebook', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  Future<void> _rateDialog(BookingItem item) async {
    final score = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rate Trip Experience', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How was the delivery for ${item.origin} to ${item.destination}?', style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                5,
                (i) => IconButton(
                  icon: const Icon(Icons.star, color: AppColors.brandYellow, size: 30),
                  onPressed: () => Navigator.pop(ctx, i + 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (score == null || !mounted) return;
    final error = await context.read<ShipmentsViewModel>().rate(item, score);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Thank you! Rating submitted.')),
      );
    }
  }
}
