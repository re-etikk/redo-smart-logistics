import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../widgets/ui_components.dart';

class TrackingScreen extends StatefulWidget {
  final BookingItem? booking;

  const TrackingScreen({super.key, this.booking});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking ??
        BookingItem(
          id: 'BK-89421',
          cargoId: 'CRG-5512',
          truckId: 'TRK-MH04-88',
          origin: 'Mumbai',
          destination: 'Delhi NCR',
          cargoType: 'Industrial Components',
          weightTons: 8.5,
          agreedPriceInr: 22100.0,
          status: 'in_transit',
          currentLat: 22.7196,
          currentLng: 75.8577,
          driverName: 'Harpreet Singh',
          driverPhone: '+91 98765 43210',
          truckReg: 'MH 04 GP 4421',
          createdAt: DateTime.now().toIso8601String(),
        );

    final truckPos = LatLng(b.currentLat ?? 22.7196, b.currentLng ?? 75.8577);
    final originPos = const LatLng(19.0760, 72.8777); // Mumbai
    final destPos = const LatLng(28.6139, 77.2090); // Delhi

    return Scaffold(
      appBar: AppBar(
        title: Text('Live GPS Tracking • ${b.id}'),
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: truckPos, zoom: 7.0),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId('truck'),
                position: truckPos,
                infoWindow: InfoWindow(title: 'Live Truck: ${b.truckReg}'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              ),
              Marker(
                markerId: const MarkerId('origin'),
                position: originPos,
                infoWindow: InfoWindow(title: 'Pickup: ${b.origin}'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
              Marker(
                markerId: const MarkerId('destination'),
                position: destPos,
                infoWindow: InfoWindow(title: 'Drop: ${b.destination}'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: [originPos, truckPos, destPos],
                color: AppColors.slateDark,
                width: 4,
              ),
            },
          ),

          // Bottom Driver Details & Status Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SHIPMENT STATUS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
                          const SizedBox(height: 4),
                          StatusBadge(status: b.status),
                        ],
                      ),
                      Text(
                        'ETA: 8 Hours (On-Time)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.brandYellow,
                        radius: 22,
                        child: const Icon(Icons.person, color: AppColors.slateDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.driverName ?? 'Assigned Driver', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text('Truck: ${b.truckReg ?? "MH 04 GP 4421"}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppColors.slateDark),
                        icon: const Icon(Icons.phone, color: Colors.white, size: 20),
                        onPressed: () {
                          final phone = b.driverPhone ?? '+919876543210';
                          launchUrl(Uri.parse('tel:$phone'));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
