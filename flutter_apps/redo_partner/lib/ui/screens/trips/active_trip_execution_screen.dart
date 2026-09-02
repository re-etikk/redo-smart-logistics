import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Future<void> _advanceWithPhoto(BuildContext context, String successMsg,
      {required String otpType}) async {
    // Step 1 - secure handover: enter the OTP the shipper shares at the dock.
    final otp = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text('Enter ${otpType == 'pickup' ? 'Pickup' : 'Delivery'} OTP'),
          content: TextField(
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: GoogleFonts.inter(
                fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 8),
            decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                helperText:
                    'Ask the ${otpType == 'pickup' ? 'shipper at loading' : 'receiver at delivery'} for the 4-digit OTP'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, c.text.trim()),
                child: const Text('Verify')),
          ],
        );
      },
    );
    if (otp == null || otp.isEmpty || !context.mounted) return;

    // Step 2 - photo e-POD.
    final picker = ImagePicker();
    var img = await picker.pickImage(source: ImageSource.camera, imageQuality: 60);
    img ??= await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!context.mounted) return;

    // Step 3 - verify OTP + upload proof + advance (all server-enforced).
    final err = await context
        .read<PartnerTripsViewModel>()
        .advanceTripStatus(trip, photoBytes: bytes, otp: otp);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? successMsg)),
      );
    }
  }

  Future<void> _advance(BuildContext context, String successMsg) async {
    final err =
        await context.read<PartnerTripsViewModel>().advanceTripStatus(trip);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? successMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.watch<PartnerTripsViewModel>();

    String actionTitle;
    VoidCallback? onAction;

    switch (trip.status) {
      case 'accepted':
        actionTitle = 'Waiting for shipper to confirm…';
        onAction = null;
        break;
      case 'confirmed':
        actionTitle = '1. Arrived at Pickup';
        onAction = () => _advance(context, 'Marked as reached pickup point.');
        break;
      case 'pickup_ready':
        actionTitle = '2. Verify Pickup OTP + e-POD Photo';
        onAction = () => _advanceWithPhoto(
            context, 'OTP verified + proof uploaded - trip is now IN TRANSIT.',
            otpType: 'pickup');
        break;
      case 'in_transit':
        actionTitle = '3. Verify Delivery OTP + e-POD Photo';
        onAction = () => _advanceWithPhoto(context,
            'OTP verified + delivered! Shipper will confirm - payout settles then.',
            otpType: 'delivery');
        break;
      case 'delivered':
        actionTitle = 'Delivered - awaiting shipper completion';
        onAction = null;
        break;
      case 'completed':
        actionTitle = '⭐ Rate the Shipper';
        onAction = () async {
          final stars = await showDialog<int>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: const Text('Rate this shipper'),
              children: [
                for (var n = 5; n >= 1; n--)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, n),
                    child: Text('${'★' * n} ($n)'),
                  ),
              ],
            ),
          );
          if (stars != null && context.mounted) {
            final err = await context
                .read<PartnerTripsViewModel>()
                .rateShipper(trip, stars);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err ?? 'Thanks! Two-way trust keeps REDO honest.')));
            }
          }
        };
        break;
      default: // pending / cancelled / disputed
        actionTitle = trip.status.toUpperCase();
        onAction = null;
    }

    final isSharing = tripsVM.gpsSharingForBooking == trip.bookingId;
    final canShareGps =
        trip.status == 'picked_up' || trip.status == 'in_transit';

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
                if (trip.shipperPhone != null && trip.shipperPhone!.isNotEmpty)
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
              isSecondary: onAction == null,
              onPressed: onAction,
            ),
            if (canShareGps) ...[
              const SizedBox(height: 10),
              RedoButton(
                title: isSharing
                    ? '🔴 Stop Live GPS Sharing'
                    : '📡 Share Live GPS with Shipper',
                isSecondary: !isSharing,
                onPressed: () async {
                  final err = await tripsVM.toggleGps(trip);
                  if (context.mounted && err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
