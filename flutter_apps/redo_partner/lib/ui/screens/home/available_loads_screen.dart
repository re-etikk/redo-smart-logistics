import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../misc/notifications_screen.dart';

const _cityLatLng = <String, LatLng>{
  'Mumbai': LatLng(19.0760, 72.8777),
  'Delhi NCR': LatLng(28.6139, 77.2090),
  'Delhi': LatLng(28.6139, 77.2090),
  'Pune': LatLng(18.5204, 73.8567),
  'Jaipur': LatLng(26.9124, 75.7873),
  'Surat': LatLng(21.1702, 72.8311),
  'Ahmedabad': LatLng(23.0225, 72.5714),
};
LatLng _posFor(String city) =>
    _cityLatLng[city] ??
    _cityLatLng[city.split(' ').first] ??
    const LatLng(23.5, 76.0);

class AvailableLoadsScreen extends StatefulWidget {
  const AvailableLoadsScreen({super.key});

  @override
  State<AvailableLoadsScreen> createState() => _AvailableLoadsScreenState();
}

class _AvailableLoadsScreenState extends State<AvailableLoadsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PartnerTripsViewModel>().fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final tripsVM = context.watch<PartnerTripsViewModel>();
    final loads = tripsVM.availableLoads;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Available Return Loads'),
        actions: [
          const NotificationsBell(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => tripsVM.fetchAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live network map - load pickup points appear here in realtime,
          // the Rapido "requests around you" feel, REDO-corridor style.
          SizedBox(
            height: 170,
            child: GoogleMap(
              initialCameraPosition:
                  const CameraPosition(target: LatLng(23.5, 76.0), zoom: 4.4),
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              liteModeEnabled: true, // smooth: static-render map header, no jank
              markers: {
                for (final l in loads)
                  Marker(
                    markerId: MarkerId('load-${l.cargoId}'),
                    position: _posFor(l.origin),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueYellow),
                    infoWindow: InfoWindow(
                        title: '${l.origin} → ${l.destination}',
                        snippet: '${l.weightTons} T • ₹${l.offeredPriceInr.round()}'),
                  ),
              },
            ),
          ),
          Expanded(
            child: _LoadsBody(tripsVM: tripsVM, loads: loads),
          ),
        ],
      ),
    );
  }
}

class _LoadsBody extends StatelessWidget {
  final PartnerTripsViewModel tripsVM;
  final List<AvailableLoad> loads;
  const _LoadsBody({required this.tripsVM, required this.loads});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return tripsVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : loads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                      const SizedBox(height: 12),
                      Text('All return loads on your corridor booked!', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: loads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final load = loads[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bolt, size: 14, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Text(
                                        load.distanceKm > 0
                                            ? '${load.distanceKm.round()} km return corridor'
                                            : 'Return corridor load',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  load.pickupWindow,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.circle, color: AppColors.success, size: 10),
                                const SizedBox(width: 8),
                                Expanded(child: Text(load.origin, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15))),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(height: 14, width: 2, color: AppColors.border),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.danger, size: 14),
                                const SizedBox(width: 6),
                                Expanded(child: Text(load.destination, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${load.smeName} • ${load.cargoType} • ${load.weightTons} Tons',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Guaranteed Payout', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                                    Text(
                                      currency.format(load.offeredPriceInr),
                                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.slateDark),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 140,
                                  child: RedoButton(
                                    title: 'Accept Load',
                                    onPressed: () async {
                                      final err = await tripsVM.acceptLoad(load);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(err ?? 'Load accepted! Shipper notified - see Active Trips.')),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
  }
}
