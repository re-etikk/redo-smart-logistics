import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/ui_components.dart';

class ActiveTripsScreen extends StatelessWidget {
  const ActiveTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.watch<PartnerTripsViewModel>();
    final trips = tripsVM.activeTrips;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('My Active Trips'),
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.inkMuted),
                  const SizedBox(height: 12),
                  Text('No active trips right now.', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _TripCard(trip: trip);
              },
            ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final ActiveTrip trip;

  const _TripCard({required this.trip});

  void _uploadPod(BuildContext context) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera);
    if (context.mounted) {
      context.read<PartnerTripsViewModel>().advanceTripStatus(trip);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('e-POD uploaded! Trip marked as Delivered & Paid.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.read<PartnerTripsViewModel>();

    String actionTitle;
    VoidCallback onAction;

    switch (trip.status) {
      case 'confirmed':
        actionTitle = '1. Arrived at Pickup';
        onAction = () => tripsVM.advanceTripStatus(trip);
        break;
      case 'pickup_ready':
        actionTitle = '2. Start Transit (In-Transit)';
        onAction = () => tripsVM.advanceTripStatus(trip);
        break;
      case 'in_transit':
        actionTitle = '3. Capture e-POD & Complete';
        onAction = () => _uploadPod(context);
        break;
      default:
        actionTitle = 'Delivered & Settled';
        onAction = () {};
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(trip.bookingId, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                StatusBadge(status: trip.status),
              ],
            ),
            const SizedBox(height: 12),
            Text('${trip.origin} ➔ ${trip.destination}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('${trip.cargoType} • ${trip.weightTons} Tons', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Shipper: ${trip.shipperName}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.slateDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.slateDark, size: 20),
                  onPressed: () => launchUrl(Uri.parse('tel:${trip.shipperPhone}')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            RedoButton(
              title: actionTitle,
              isSecondary: trip.status == 'delivered',
              onPressed: trip.status == 'delivered' ? null : onAction,
            ),
          ],
        ),
      ),
    );
  }
}
