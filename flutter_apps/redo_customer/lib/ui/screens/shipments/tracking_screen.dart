import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/ui_components.dart';
import '../../../viewmodels/booking_viewmodel.dart' show majorCities;

/// LIVE tracking: history from /tracking + realtime tracking_events inserts.
/// The truck marker moves when the driver's app streams real GPS
/// (is_simulated: false) - and simulated demo points are honestly labeled.
class TrackingScreen extends StatefulWidget {
  final BookingItem? booking;
  const TrackingScreen({super.key, this.booking});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  final List<Map<String, dynamic>> _points = [];
  RealtimeChannel? _channel;

  LatLng _cityLatLng(String name) {
    for (final c in majorCities) {
      if (name.startsWith(c.name.split(' ').first)) return c.latLng;
    }
    return majorCities.first.latLng;
  }

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    if (b != null) {
      SupabaseService.getTrackingHistory(b.id).then((h) {
        if (!mounted) return;
        setState(() {
          _points
            ..clear()
            ..addAll(h);
        });
        _follow();
      }).catchError((_) {});
      _channel = SupabaseService.subscribeTracking(b.id, (pt) {
        if (!mounted) return;
        setState(() => _points.add(pt));
        _follow();
      });
    }
  }

  @override
  void dispose() {
    if (_channel != null) SupabaseService.removeChannel(_channel!);
    super.dispose();
  }

  void _follow() {
    if (_points.isEmpty || _mapController == null) return;
    final last = _points.last;
    _mapController!.animateCamera(CameraUpdate.newLatLng(
      LatLng((last['lat'] as num).toDouble(), (last['lng'] as num).toDouble()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    if (b == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live GPS Tracking')),
        body: const Center(child: Text('Open a shipment to track it live.')),
      );
    }

    final originPos = _cityLatLng(b.origin);
    final destPos = _cityLatLng(b.destination);
    final last = _points.isEmpty ? null : _points.last;
    final truckPos = last != null
        ? LatLng((last['lat'] as num).toDouble(), (last['lng'] as num).toDouble())
        : null;
    final isSimulated = last?['is_simulated'] == true;
    String lastSeen = '';
    if (last != null) {
      final t = DateTime.tryParse('${last['created_at']}')?.toLocal();
      if (t != null) lastSeen = DateFormat('h:mm:ss a').format(t);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Live GPS Tracking • ${b.id.substring(0, 8).toUpperCase()}')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: truckPos ??
                  LatLng((originPos.latitude + destPos.latitude) / 2,
                      (originPos.longitude + destPos.longitude) / 2),
              zoom: truckPos != null ? 7.0 : 5.3,
            ),
            onMapCreated: (c) {
              _mapController = c;
              _follow();
            },
            markers: {
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
              if (truckPos != null)
                Marker(
                  markerId: const MarkerId('truck'),
                  position: truckPos,
                  infoWindow: InfoWindow(title: 'Live Truck: ${b.truckReg ?? ''}'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('corridor'),
                points: [originPos, destPos],
                color: AppColors.border,
                width: 3,
              ),
              if (_points.length > 1)
                Polyline(
                  polylineId: const PolylineId('trail'),
                  points: _points
                      .map((p) => LatLng(
                          (p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
                      .toList(),
                  color: AppColors.slateDark,
                  width: 4,
                ),
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4)),
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
                          Text('SHIPMENT STATUS',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkMuted)),
                          const SizedBox(height: 4),
                          StatusBadge(status: b.status),
                        ],
                      ),
                      Text(
                        truckPos == null
                            ? 'Waiting for driver GPS…'
                            : isSimulated
                                ? 'Demo tracking • Simulated'
                                : 'LIVE • $lastSeen',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: truckPos == null
                                ? AppColors.inkMuted
                                : isSimulated
                                    ? AppColors.warning
                                    : AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.brandYellow,
                        radius: 22,
                        child: Icon(Icons.person, color: AppColors.slateDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.driverName ?? 'Assigned Driver',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                            Text('Truck: ${b.truckReg ?? '—'}',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.inkMuted)),
                          ],
                        ),
                      ),
                      if (b.driverPhone != null && b.driverPhone!.isNotEmpty)
                        IconButton.filled(
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.slateDark),
                          icon: const Icon(Icons.phone,
                              color: Colors.white, size: 20),
                          onPressed: () =>
                              launchUrl(Uri.parse('tel:${b.driverPhone}')),
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
