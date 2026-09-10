import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../misc/notifications_screen.dart';

class TrackingScreen extends StatefulWidget {
  final BookingItem? booking;
  const TrackingScreen({super.key, this.booking});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  BookingItem? _selected;
  List<Map<String, dynamic>> _events = [];
  bool _loading = false;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.booking;
    if (_selected != null) {
      _searchController.text = _selected!.id.substring(0, _selected!.id.length > 8 ? 8 : _selected!.id.length).toUpperCase();
      _loadTracking();
    } else {
      Future.microtask(() => context.read<ShipmentsViewModel>().fetchShipments(silent: true));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTracking() async {
    final b = _selected;
    if (b == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await SupabaseService.getTrackingHistory(b.id);
      if (mounted) setState(() => _events = events);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _searchBookingById(String query, List<BookingItem> all) {
    if (query.trim().isEmpty) return;
    final q = query.trim().toLowerCase();
    final match = all.firstWhere(
      (b) => b.id.toLowerCase().contains(q),
      orElse: () => all.firstWhere(
        (b) => b.origin.toLowerCase().contains(q) || b.destination.toLowerCase().contains(q),
        orElse: () => all.first,
      ),
    );
    setState(() {
      _selected = match;
    });
    _loadTracking();
  }

  @override
  Widget build(BuildContext context) {
    final shipmentsVM = context.watch<ShipmentsViewModel>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
                onRefresh: _selected == null ? shipmentsVM.fetchShipments : _loadTracking,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    // Screen Title
                    Text(
                      'Track Shipment',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live GPS updates and milestone tracking for your cargo.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 14),

                    // Tracking Search Bar
                    _buildSearchBar(shipmentsVM.shipments),
                    const SizedBox(height: 16),

                    // If a booking is selected -> Show Live Tracking View
                    if (_selected != null) ...[
                      _buildTrackingView(_selected!, currency),
                    ] else ...[
                      // If no booking is selected -> Show Booking Selector
                      _buildBookingSelector(shipmentsVM),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(List<BookingItem> all) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.inkMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Enter Booking ID to track...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (val) => _searchBookingById(val, all),
            ),
          ),
          if (_selected != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selected = null;
                  _events = [];
                });
              },
            ),
          ElevatedButton(
            onPressed: () => _searchBookingById(_searchController.text, all),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text('Track', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSelector(ShipmentsViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }
    if (vm.shipments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off_outlined, size: 48, color: AppColors.inkMuted),
            const SizedBox(height: 12),
            Text('No active bookings to track', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Book a truck from the Home tab to see real-time vehicle GPS tracking here.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select an active booking to track', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...vm.shipments.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {
              setState(() {
                _selected = b;
                _searchController.text = b.id.substring(0, b.id.length > 8 ? 8 : b.id.length).toUpperCase();
              });
              _loadTracking();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const RedoTruckHeroGraphic(height: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${b.origin} → ${b.destination}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Booking #${b.id.substring(0, b.id.length > 8 ? 8 : b.id.length).toUpperCase()} · ${b.cargoType}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                  StatusBadge(status: b.status),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTrackingView(BookingItem b, NumberFormat currency) {
    final statusText = _statusMessage(b.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Route Map Preview Container
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(24.5, 78.5), // Central India overview
                  zoom: 5.5,
                ),
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                liteModeEnabled: true,
                markers: {
                  if (b.currentLat != null && b.currentLng != null)
                    Marker(
                      markerId: const MarkerId('truck_live'),
                      position: LatLng(b.currentLat!, b.currentLng!),
                      infoWindow: const InfoWindow(title: 'Live Truck'),
                    ),
                },
              ),

              // Top Callout Bubble
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, color: AppColors.brandYellow, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusText,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      if (b.status == 'in_transit')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
                          child: Text('LIVE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ),

              // Route endpoints overlay
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${b.origin} → ${b.destination}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                      Text('${b.weightTons.toStringAsFixed(1)} T', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Booking Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shipment Status', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
                  StatusBadge(status: b.status),
                ],
              ),
              const SizedBox(height: 14),
              _buildStepper(b.status),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cargo Type', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                      Text(b.cargoType.isEmpty ? 'General Cargo' : b.cargoType, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Agreed Payout', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                      Text(currency.format(b.agreedPriceInr), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Driver Info Card (if assigned)
        if (b.driverName?.isNotEmpty == true || b.driverPhone?.isNotEmpty == true)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.brandYellow,
                  child: const Icon(Icons.person, color: AppColors.slateDark, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.driverName ?? 'Assigned Driver', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800)),
                      if (b.truckReg?.isNotEmpty == true)
                        Text('Truck: ${b.truckReg}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                    ],
                  ),
                ),
                if (b.driverPhone?.isNotEmpty == true) ...[
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.success),
                    tooltip: 'Call driver',
                    onPressed: () => launchUrl(Uri.parse('tel:${b.driverPhone}')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message_outlined, color: AppColors.slateDark),
                    tooltip: 'Message driver',
                    onPressed: () => launchUrl(Uri.parse('sms:${b.driverPhone}')),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),

        // Error message if tracking fails
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.danger))),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Tracking Events List / OTP info
        if (b.pickupOtp != null && ['confirmed', 'pickup_ready'].contains(b.status)) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.pin, color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pickup Verification OTP', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                      Text('Share OTP with the driver upon arrival at pickup point.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                    ],
                  ),
                ),
                Text(b.pickupOtp!, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.slateDark)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Tracking History Events
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_events.isNotEmpty) ...[
          Text('Live Milestone History', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: _events.reversed.take(4).map((e) {
                final date = DateTime.tryParse('${e['timestamp'] ?? ''}')?.toLocal();
                final timeStr = date != null ? DateFormat('d MMM, h:mm a').format(date) : 'Recent';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e['description'] ?? 'GPS Location Ping', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      Text(timeStr, style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Choose another booking CTA
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() {
              _selected = null;
              _events = [];
            }),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Track a different booking'),
          ),
        ),
      ],
    );
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'in_transit':
        return 'Your shipment is on the way.';
      case 'picked_up':
        return 'Cargo picked up. Journey started.';
      case 'pickup_ready':
        return 'Partner has arrived at pickup location.';
      case 'confirmed':
        return 'Truck assigned. Partner heading to pickup.';
      case 'delivered':
      case 'completed':
        return 'Shipment successfully delivered.';
      default:
        return 'Booking created and verified.';
    }
  }

  Widget _buildStepper(String status) {
    const steps = ['Booked', 'Picked Up', 'On The Way', 'Delivered'];
    int current = 0;
    if (['confirmed', 'pickup_ready'].contains(status)) {
      current = 1;
    } else if (['picked_up', 'in_transit'].contains(status)) {
      current = 2;
    } else if (['delivered', 'completed'].contains(status)) {
      current = 3;
    }

    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= current;
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: done ? AppColors.brandYellow : AppColors.inkFaint,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i],
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                      color: done ? AppColors.slateDark : AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: i < current ? AppColors.brandYellow : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
