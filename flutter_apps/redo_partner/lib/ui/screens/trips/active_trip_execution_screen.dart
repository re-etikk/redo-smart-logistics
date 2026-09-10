import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../misc/notifications_screen.dart';

class ActiveTripsScreen extends StatefulWidget {
  final VoidCallback? onFindLoadsPressed;
  const ActiveTripsScreen({super.key, this.onFindLoadsPressed});

  @override
  State<ActiveTripsScreen> createState() => _ActiveTripsScreenState();
}

class _ActiveTripsScreenState extends State<ActiveTripsScreen> {
  String _selectedFilter = 'ongoing'; // ongoing, completed, cancelled

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PartnerTripsViewModel>().fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PartnerTripsViewModel>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final filteredTrips = vm.activeTrips.where((trip) {
      if (_selectedFilter == 'ongoing') {
        return !['completed', 'cancelled'].contains(trip.status);
      } else if (_selectedFilter == 'completed') {
        return ['completed', 'delivered'].contains(trip.status);
      } else if (_selectedFilter == 'cancelled') {
        return trip.status == 'cancelled';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RedoBrandHeader(
              subtitle: 'Partner (Trucks)',
              onNotificationTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Trips',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage active assignments, route updates and delivery proof.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),

            // Tabs: Ongoing, Completed, Cancelled
            _buildTabs(),

            // Trip Cards or Clean Empty State
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandYellow,
                onRefresh: vm.fetchAll,
                child: _buildTripsList(vm, filteredTrips, currency),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      ('Ongoing', 'ongoing'),
      ('Completed', 'completed'),
      ('Cancelled', 'cancelled'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedFilter == tab.$2;
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
              onSelected: (_) => setState(() => _selectedFilter = tab.$2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripsList(
    PartnerTripsViewModel vm,
    List<ActiveTrip> trips,
    NumberFormat currency,
  ) {
    if (vm.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    if (vm.errorMessage != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.inkMuted),
                const SizedBox(height: 12),
                Text('Could not load trips', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(vm.errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
                const SizedBox(height: 16),
                TextButton.icon(onPressed: vm.fetchAll, icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ],
            ),
          ),
        ],
      );
    }

    if (trips.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              children: [
                Icon(Icons.local_shipping_outlined, size: 52, color: AppColors.inkMuted),
                const SizedBox(height: 14),
                Text(
                  _selectedFilter == 'ongoing' ? 'No active trips right now' : 'No $_selectedFilter trips',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedFilter == 'ongoing'
                      ? 'Accept open cargo loads from the Home tab to start hauling and earning.'
                      : 'Completed trips and payouts will be cataloged here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 20),
                if (_selectedFilter == 'ongoing')
                  ElevatedButton.icon(
                    onPressed: widget.onFindLoadsPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: AppColors.slateDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.search),
                    label: Text('Find Available Loads', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
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
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) => _buildTripCard(trips[index], currency, vm),
    );
  }

  Widget _buildTripCard(
    ActiveTrip trip,
    NumberFormat currency,
    PartnerTripsViewModel vm,
  ) {
    final isGpsLive = vm.gpsSharingForBooking == trip.bookingId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
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
          // Route Header & Status Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.origin} → ${trip.destination}',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              if (trip.isInstant) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚡ INSTANT',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ],
              StatusBadge(status: trip.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${trip.weightTons.toStringAsFixed(1)} T · ${trip.cargoType}',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
          ),
          if (trip.pickupAddress != null && trip.pickupAddress!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Pickup: ${trip.pickupAddress}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (trip.dropAddress != null && trip.dropAddress!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: AppColors.danger),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Drop: ${trip.dropAddress}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Mini Map Preview Container
          Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(24.5, 78.5),
                    zoom: 5.2,
                  ),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  liteModeEnabled: true,
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
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
                        Text('Assigned Route', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        Text('Agreed: ${currency.format(trip.payoutInr)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slateDark)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Google Maps Live Turn-by-Turn Redirection Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchGoogleMapsNavigation(trip),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: AppColors.brandYellow,
                side: const BorderSide(color: AppColors.brandYellow, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              icon: const Icon(Icons.navigation, size: 18, color: AppColors.brandYellow),
              label: Text(
                'Open in Google Maps (Navigate)',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3-Step Live Stepper: Picked Up -> On the way -> Delivered
          _build3StepStepper(trip.status),
          const SizedBox(height: 14),

          // Shipper Info Row (with Call button)
          if (trip.shipperName.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.brandYellow.withValues(alpha: 0.2),
                    child: const Icon(Icons.business, size: 16, color: AppColors.slateDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.shipperName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                        if (trip.shipperPhone?.isNotEmpty == true)
                          Text(trip.shipperPhone!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                  if (trip.shipperPhone?.isNotEmpty == true)
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.success, size: 20),
                      tooltip: 'Call Customer',
                      onPressed: () => launchUrl(Uri.parse('tel:${trip.shipperPhone}')),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          const Divider(height: 1),
          const SizedBox(height: 12),

          // Action Buttons: Advance Trip Status + Live GPS
          Row(
            children: [
              Expanded(
                child: _buildAdvanceButton(vm, trip),
              ),
              if (['picked_up', 'in_transit'].contains(trip.status)) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: Icon(
                    isGpsLive ? Icons.gps_off : Icons.gps_fixed,
                    color: isGpsLive ? AppColors.danger : AppColors.success,
                  ),
                  tooltip: isGpsLive ? 'Stop Live GPS' : 'Start Live GPS',
                  onPressed: () async {
                    final err = await vm.toggleGps(trip);
                    if (mounted && err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3StepStepper(String status) {
    const steps = ['Picked Up', 'On the way', 'Delivered'];
    int current = 0;
    if (['picked_up', 'in_transit'].contains(status)) {
      current = 1;
    } else if (['delivered', 'completed'].contains(status)) {
      current = 2;
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
                      fontSize: 10,
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
                    margin: const EdgeInsets.only(bottom: 16),
                    color: i < current ? AppColors.brandYellow : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAdvanceButton(PartnerTripsViewModel vm, ActiveTrip trip) {
    String title = 'Trip Completed';
    IconData icon = Icons.check;
    bool requiresProof = false;

    if (trip.status == 'confirmed') {
      title = 'Arrived at Pickup';
      icon = Icons.location_on_outlined;
    } else if (trip.status == 'pickup_ready') {
      title = 'Verify Pickup (Enter OTP)';
      icon = Icons.inventory_2_outlined;
      requiresProof = true;
    } else if (trip.status == 'in_transit') {
      title = 'Verify Delivery (Enter OTP)';
      icon = Icons.task_alt;
      requiresProof = true;
    } else if (trip.status == 'delivered' || trip.status == 'completed') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Text('Trip Completed & Settled', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.success)),
      );
    }

    return RedoButton(
      title: title,
      icon: icon,
      onPressed: () => _advanceTrip(vm, trip, requiresProof),
    );
  }

  Future<void> _advanceTrip(
    PartnerTripsViewModel vm,
    ActiveTrip trip,
    bool requiresProof,
  ) async {
    String? otp;
    Uint8List? photoBytes;

    if (requiresProof) {
      final step = trip.status == 'pickup_ready' ? 'Pickup' : 'Delivery';
      otp = await _showOtpDialog(step);
      if (otp == null || !mounted) return;

      final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 60);
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera proof photo is required to complete this step.')),
          );
        }
        return;
      }
      photoBytes = await image.readAsBytes();
    }

    final error = await vm.advanceTripStatus(trip, otp: otp, photoBytes: photoBytes);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip status updated successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<String?> _showOtpDialog(String stepName) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter $stepName OTP', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ask the shipper for the 4-digit verification OTP.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: '4-Digit OTP',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Verify & Take Photo')),
        ],
      ),
    );
  }
  Future<void> _launchGoogleMapsNavigation(ActiveTrip trip) async {
    final dest = (trip.dropAddress != null && trip.dropAddress!.isNotEmpty)
        ? trip.dropAddress!
        : trip.destination;
    final orig = (trip.pickupAddress != null && trip.pickupAddress!.isNotEmpty)
        ? trip.pickupAddress!
        : trip.origin;

    final navUri = Uri.parse('google.navigation:q=${Uri.encodeComponent(dest)}&mode=d');
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(orig)}&destination=${Uri.encodeComponent(dest)}&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(navUri)) {
        await launchUrl(navUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch Google Maps: $e')),
          );
        }
      }
    }
  }
}
