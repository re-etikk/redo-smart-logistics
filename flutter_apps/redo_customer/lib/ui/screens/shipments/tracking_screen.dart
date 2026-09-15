import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_strings.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/routing_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../chat/direct_chat_screen.dart';
import '../misc/notifications_screen.dart';

class TrackingScreen extends StatefulWidget {
  final BookingItem? booking;
  final void Function(int index)? onTabChangeRequested;

  const TrackingScreen({
    super.key,
    this.booking,
    this.onTabChangeRequested,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  BookingItem? _selected;
  List<Map<String, dynamic>> _events = [];
  bool _loading = false;
  String? _error;
  final _searchController = TextEditingController();

  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];
  LatLng? _originLatLng;
  LatLng? _destLatLng;
  LatLng? _truckLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  DateTime _lastUpdated = DateTime.now();
  RealtimeChannel? _trackingChannel;

  static const Map<String, LatLng> _knownHubs = {
    'delhi': LatLng(28.6139, 77.2090),
    'mumbai': LatLng(19.0760, 72.8777),
    'pune': LatLng(18.5204, 73.8567),
    'jaipur': LatLng(26.9124, 75.7873),
    'surat': LatLng(21.1702, 72.8311),
    'ahmedabad': LatLng(23.0225, 72.5714),
    'bengaluru': LatLng(12.9716, 77.5946),
    'bangalore': LatLng(12.9716, 77.5946),
    'hyderabad': LatLng(17.3850, 78.4867),
    'kolkata': LatLng(22.5726, 88.3639),
    'chennai': LatLng(13.0827, 80.2707),
    'indore': LatLng(22.7196, 75.8577),
    'lucknow': LatLng(26.8467, 80.9462),
    'nagpur': LatLng(21.1458, 79.0882),
    'kanpur': LatLng(26.4499, 80.3319),
    'patna': LatLng(25.6111, 85.1440),
    'bhopal': LatLng(23.2599, 77.4126),
    'ludhiana': LatLng(30.9010, 75.8573),
    'agra': LatLng(27.1767, 78.0081),
    'vadodara': LatLng(22.3072, 73.1812),
    'chandigarh': LatLng(30.7333, 76.7794),
    'coimbatore': LatLng(11.0168, 76.9558),
    'visakhapatnam': LatLng(17.6868, 83.2185),
    'kochi': LatLng(9.9312, 76.2673),
    'guwahati': LatLng(26.1445, 91.7362),
    'varanasi': LatLng(25.3176, 82.9739),
    'amritsar': LatLng(31.6340, 74.8723),
    'navi mumbai': LatLng(19.0330, 73.0297),
    'noida': LatLng(28.5355, 77.3910),
    'gurugram': LatLng(28.4595, 77.0266),
    'gurgaon': LatLng(28.4595, 77.0266),
    'ghaziabad': LatLng(28.6692, 77.4538),
    'faridabad': LatLng(28.4089, 77.3178),
  };

  static LatLng _resolveCity(String rawName, LatLng fallback) {
    final clean = rawName.toLowerCase();
    for (final entry in _knownHubs.entries) {
      if (clean.contains(entry.key)) {
        return entry.value;
      }
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.booking;
    if (_selected != null) {
      _searchController.text = _selected!.id.substring(
        0,
        _selected!.id.length > 8 ? 8 : _selected!.id.length,
      ).toUpperCase();
      _initTrackingForSelected();
    } else {
      Future.microtask(() async {
        if (!mounted) return;
        final vm = context.read<ShipmentsViewModel>();
        await vm.fetchShipments(silent: true);
        if (mounted && _selected == null) {
          final active = vm.shipments.where((b) {
            final st = b.status.toLowerCase();
            return ['in_transit', 'picked_up', 'confirmed', 'pickup_ready'].contains(st);
          }).toList();
          if (active.isNotEmpty) {
            setState(() {
              _selected = active.first;
              _searchController.text = _selected!.id.substring(
                0,
                _selected!.id.length > 8 ? 8 : _selected!.id.length,
              ).toUpperCase();
            });
            _initTrackingForSelected();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_trackingChannel != null) {
      SupabaseService.removeChannel(_trackingChannel!);
    }
    super.dispose();
  }

  Future<void> _initTrackingForSelected() async {
    final b = _selected;
    if (b == null) return;

    setState(() {
      _lastUpdated = DateTime.now();
      _error = null;
    });

    _loadTracking();
    await _buildRouteAndMarkers(b);

    if (_trackingChannel != null) {
      SupabaseService.removeChannel(_trackingChannel!);
      _trackingChannel = null;
    }
    try {
      _trackingChannel = SupabaseService.subscribeTracking(b.id, (point) {
        if (!mounted) return;
        setState(() {
          _events.insert(0, point);
          final lat = (point['lat'] as num?)?.toDouble();
          final lng = (point['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            _truckLatLng = LatLng(lat, lng);
            _updateTruckMarker(b);
          }
          _lastUpdated = DateTime.now();
        });
      });
    } catch (_) {}
  }

  Future<void> _buildRouteAndMarkers(BookingItem b) async {
    final originCoord = _resolveCity(b.origin, const LatLng(28.6139, 77.2090));
    final destCoord = _resolveCity(b.destination, const LatLng(19.0760, 72.8777));

    _originLatLng = originCoord;
    _destLatLng = destCoord;

    List<LatLng> points = [];
    try {
      final routeInfo = await RoutingService.getDrivingRoute(originCoord, destCoord);
      if (routeInfo != null && routeInfo.points.isNotEmpty) {
        points = routeInfo.points;
      }
    } catch (_) {}

    if (points.isEmpty) {
      points = _generateHighwayPoints(originCoord, destCoord);
    }

    _routePoints = points;

    if (b.currentLat != null && b.currentLng != null) {
      _truckLatLng = LatLng(b.currentLat!, b.currentLng!);
    } else if (points.isNotEmpty) {
      final st = b.status.toLowerCase();
      double fraction = 0.55;
      if (['confirmed', 'pickup_ready'].contains(st)) {
        fraction = 0.05;
      } else if (st == 'picked_up') {
        fraction = 0.20;
      } else if (st == 'in_transit') {
        fraction = 0.55;
      } else if (['out_for_delivery', 'delivered', 'completed'].contains(st)) {
        fraction = 0.95;
      }
      final idx = (points.length * fraction).clamp(0, points.length - 1).toInt();
      _truckLatLng = points[idx];
    } else {
      _truckLatLng = originCoord;
    }

    final newMarkers = <Marker>{
      Marker(
        markerId: const MarkerId('origin'),
        position: originCoord,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Origin: ${b.origin}'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destCoord,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination: ${b.destination}'),
      ),
    };

    if (_truckLatLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('truck_live'),
          position: _truckLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'REDO Truck (${b.cargoType})',
            snippet: 'Status: ${_statusTitle(b.status)}',
          ),
        ),
      );
    }

    final newPolylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('tracking_corridor'),
        points: _routePoints,
        color: const Color(0xFF2563EB),
        width: 4,
      ),
    };

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = newPolylines;
      });

      if (_mapController != null && _routePoints.isNotEmpty) {
        _fitMapToBounds(originCoord, destCoord);
      }
    }
  }

  void _updateTruckMarker(BookingItem b) {
    if (_truckLatLng == null) return;
    _markers.removeWhere((m) => m.markerId.value == 'truck_live');
    _markers.add(
      Marker(
        markerId: const MarkerId('truck_live'),
        position: _truckLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'REDO Truck (${b.cargoType})',
          snippet: 'Status: ${_statusTitle(b.status)}',
        ),
      ),
    );
  }

  List<LatLng> _generateHighwayPoints(LatLng start, LatLng end) {
    final list = <LatLng>[];
    const steps = 14;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      final curve = sin(t * pi) * 0.45;
      list.add(LatLng(lat + (curve * 0.3), lng + curve));
    }
    return list;
  }

  void _fitMapToBounds(LatLng origin, LatLng dest) {
    final minLat = min(origin.latitude, dest.latitude) - 0.4;
    final maxLat = max(origin.latitude, dest.latitude) + 0.4;
    final minLng = min(origin.longitude, dest.longitude) - 0.4;
    final maxLng = max(origin.longitude, dest.longitude) + 0.4;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 36),
    );
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
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        // Do not display false error for unaccepted/open cargo requests or missing telemetry pings
        if (errStr.contains('not found') || errStr.contains('404') || b.status.toLowerCase() == 'open' || b.status.toLowerCase() == 'pending') {
          setState(() {
            _events = [];
            _error = null;
          });
        } else {
          setState(() => _error = e.toString().replaceAll('Exception: ', ''));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchBooking(String query, List<BookingItem> all) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;

    final localMatch = all.where((b) {
      return b.id.toLowerCase().contains(q) ||
          b.cargoId.toLowerCase().contains(q) ||
          b.origin.toLowerCase().contains(q) ||
          b.destination.toLowerCase().contains(q) ||
          (b.truckReg?.toLowerCase().contains(q) ?? false) ||
          (b.driverPhone?.contains(q) ?? false);
    }).toList();

    if (localMatch.isNotEmpty) {
      setState(() {
        _selected = localMatch.first;
      });
      await _initTrackingForSelected();
      return;
    }

    setState(() => _loading = true);
    try {
      final remote = await SupabaseService.getBookingByIdOrSearch(query.trim());
      if (remote != null) {
        setState(() {
          _selected = remote;
        });
        await _initTrackingForSelected();
        return;
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active consignment found matching "$query"'),
          backgroundColor: AppColors.slateDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openGoogleMapsTracking(BookingItem b) async {
    String originParam;
    if (_truckLatLng != null) {
      originParam = '${_truckLatLng!.latitude},${_truckLatLng!.longitude}';
    } else if (b.currentLat != null && b.currentLng != null) {
      originParam = '${b.currentLat},${b.currentLng}';
    } else {
      originParam = Uri.encodeComponent(b.origin);
    }
    final destParam = Uri.encodeComponent(b.destination);
    final mapUrl =
        'https://www.google.com/maps/dir/?api=1&origin=$originParam&destination=$destParam&travelmode=driving';
    final uri = Uri.parse(mapUrl);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Maps: $e')),
        );
      }
    }
  }

  Future<void> _shareTracking(BookingItem b) async {
    final originEnc = Uri.encodeComponent(b.origin);
    final destEnc = Uri.encodeComponent(b.destination);
    final mapUrl =
        'https://www.google.com/maps/dir/?api=1&origin=$originEnc&destination=$destEnc&travelmode=driving';
    final idShort = b.id.substring(0, b.id.length > 8 ? 8 : b.id.length).toUpperCase();

    final text = 'REDO Live Consignment Tracking\n'
        'Booking ID: #$idShort\n'
        'Route: ${b.origin} -> ${b.destination}\n'
        'Status: ${_statusTitle(b.status)}\n'
        'Weight: ${b.weightTons.toStringAsFixed(1)} T • ${b.cargoType}\n'
        'Live Route Map: $mapUrl\n\n'
        'Tracked on REDO Transport & Logistics';

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tracking link & consignment details copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.slateDark,
        ),
      );
    }
  }

  String _formatUpdatedAgo() {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    return '${diff.inHours} hrs ago';
  }

  String _formatEstDelivery(BookingItem b) {
    final created = DateTime.tryParse(b.createdAt) ?? DateTime.now();
    final est = created.add(const Duration(hours: 28));
    return DateFormat('d MMM yyyy, hh:mm a').format(est);
  }

  String _statusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'in_transit':
        return 'In Transit 🛣️';
      case 'picked_up':
        return 'Picked Up 📦';
      case 'pickup_ready':
        return 'Arrived at Pickup';
      case 'confirmed':
      case 'assigned':
        return 'Driver Assigned 🚛';
      case 'open':
      case 'pending':
      case 'matching':
        return 'Finding Truck Partner... ⏳';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
      case 'completed':
        return 'Delivered & Completed ✅';
      default:
        return 'Finding Truck Partner... ⏳';
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipmentsVM = context.watch<ShipmentsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                onRefresh: () async {
                  if (_selected != null) {
                    await _initTrackingForSelected();
                  } else {
                    await shipmentsVM.fetchShipments();
                  }
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                  children: [
                    _buildHeaderRow(_selected, isDark),
                    const SizedBox(height: 14),
                    _buildSearchBar(shipmentsVM.shipments, isDark),
                    const SizedBox(height: 16),
                    if (_selected != null) ...[
                      if (_error != null) _buildErrorBanner(_error!),
                      _buildLiveTrackingHeader(isDark),
                      const SizedBox(height: 10),
                      _buildMapPreview(_selected!, isDark),
                      const SizedBox(height: 14),
                      _buildShipmentOverviewCard(_selected!, isDark),
                      const SizedBox(height: 12),
                      _buildStepperCard(_selected!, isDark),
                      const SizedBox(height: 12),
                      _buildDriverAndTruckCards(_selected!, isDark),
                      const SizedBox(height: 12),
                      _buildOnTimeBanner(isDark),
                      const SizedBox(height: 16),
                      _buildBottomActions(_selected!, isDark),
                    ] else ...[
                      _buildEmptyStateOrSelector(shipmentsVM, isDark),
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

  Widget _buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BookingItem? b, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.of(context, 'trackShipment'),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slateDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Real-time location. Total visibility. Peace of mind.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (b != null)
          OutlinedButton.icon(
            onPressed: () => _shareTracking(b),
            icon: Icon(
              Icons.share_outlined,
              size: 14,
              color: isDark ? Colors.white : AppColors.slateDark,
            ),
            label: Text(
              'Share',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.slateDark,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(List<BookingItem> all, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.inkMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white : AppColors.slateDark,
              ),
              decoration: InputDecoration(
                hintText: 'Enter Booking ID / LR Number / Mobile',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppColors.darkInkMuted : AppColors.inkFaint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (val) => _searchBooking(val, all),
            ),
          ),
          if (_selected != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.inkMuted),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selected = null;
                  _events = [];
                });
              },
            ),
          ElevatedButton(
            onPressed: () => _searchBooking(_searchController.text, all),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Track',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTrackingHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.of(context, 'liveTracking'),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.slateDark,
          ),
        ),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Updated ${_formatUpdatedAgo()}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                if (_selected != null) _initTrackingForSelected();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: isDark ? Colors.white : AppColors.slateDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPreview(BookingItem b, bool isDark) {
    final originCity = b.origin.split(' ').first;
    final destCity = b.destination.split(' ').first;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Google Map Interactive View
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _truckLatLng ?? _originLatLng ?? const LatLng(23.5, 77.5),
              zoom: 5.8,
            ),
            polylines: _polylines,
            markers: _markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_originLatLng != null && _destLatLng != null) {
                _fitMapToBounds(_originLatLng!, _destLatLng!);
              }
            },
            onTap: (_) => _openGoogleMapsTracking(b),
          ),

          // Origin Pill Badge (Top-center / top-left)
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    originCity,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slateDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Destination Pill Badge (Bottom-center / bottom-left)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    destCity,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slateDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Speed Tooltip Bubble (Above truck / center)
          Positioned(
            top: 75,
            left: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    b.status.toLowerCase() == 'in_transit' ? 'Moving' : _statusTitle(b.status),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slateDark,
                    ),
                  ),
                  Text(
                    b.status.toLowerCase() == 'in_transit' ? '72 km/h' : '0 km/h',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Zoom Controls (Top Right)
          Positioned(
            top: 10,
            right: 12,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: isDark ? Colors.white : AppColors.slateDark,
                          ),
                        ),
                      ),
                      Container(
                        height: 1,
                        width: 24,
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                      InkWell(
                        onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: isDark ? Colors.white : AppColors.slateDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      if (_originLatLng != null && _destLatLng != null) {
                        _fitMapToBounds(_originLatLng!, _destLatLng!);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.my_location,
                        size: 16,
                        color: isDark ? Colors.white : AppColors.slateDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Right: View on Maps CTA
          Positioned(
            bottom: 12,
            right: 12,
            child: InkWell(
              onTap: () => _openGoogleMapsTracking(b),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFEA4335), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.of(context, 'viewOnMaps'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slateDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentOverviewCard(BookingItem b, bool isDark) {
    final idDisplay = b.id.length > 9 ? b.id.substring(0, 9).toUpperCase() : b.id.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Redo Yellow Commercial Truck Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/tracking_truck_thumb.png',
              width: 52,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                width: 52,
                height: 42,
                color: const Color(0xFFFEF3C7),
                child: const Icon(Icons.local_shipping, color: AppColors.brandYellow, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 14,
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusTitle(b.status),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Est. Delivery',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkFaint),
              ),
              Text(
                _formatEstDelivery(b),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.slateDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperCard(BookingItem b, bool isDark) {
    final st = b.status.toLowerCase();
    final createdDate = DateTime.tryParse(b.createdAt) ?? DateTime.now();

    final step1Time = DateFormat('d MMM\n10:30 AM').format(createdDate);
    final hasDriverAssigned = ['confirmed', 'assigned', 'pickup_ready', 'picked_up', 'in_transit', 'delivered', 'completed'].contains(st) ||
        (b.driverName != null && b.driverName!.trim().isNotEmpty && b.driverName != 'Assigning Driver...');
    final step2Time = hasDriverAssigned
        ? DateFormat('d MMM\n04:20 PM').format(createdDate)
        : 'Matching... ⏳';
    final step3Time = ['picked_up', 'in_transit', 'delivered', 'completed'].contains(st)
        ? DateFormat('d MMM\n09:15 AM').format(createdDate.add(const Duration(hours: 18)))
        : '—';
    final step4Time = ['in_transit', 'delivered', 'completed'].contains(st)
        ? '${DateFormat('d MMM').format(createdDate.add(const Duration(hours: 28)))}\n(Active)'
        : '—';
    final step5Time = ['delivered', 'completed'].contains(st) ? 'Delivered' : '—';

    // Status progression logic
    int progressStage = 1; // Request Placed / Open
    if (hasDriverAssigned) progressStage = 2;
    if (['picked_up'].contains(st)) progressStage = 3;
    if (['in_transit', 'out_for_delivery'].contains(st)) progressStage = 4;
    if (['delivered', 'completed'].contains(st)) progressStage = 5;

    final steps = [
      {'title': 'Request Placed', 'subtitle': step1Time, 'stage': 1},
      {'title': 'Driver Assigned', 'subtitle': step2Time, 'stage': 2},
      {'title': 'Picked Up', 'subtitle': step3Time, 'stage': 3},
      {'title': 'In Transit', 'subtitle': step4Time, 'stage': 4},
      {'title': 'Delivered', 'subtitle': step5Time, 'stage': 5},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (i) {
          final item = steps[i];
          final stepNum = item['stage'] as int;
          final isPast = stepNum < progressStage;
          final isCurrent = stepNum == progressStage;
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
                            : (stepNum <= progressStage
                                ? AppColors.brandYellow
                                : (isDark ? AppColors.darkBorder : AppColors.border)),
                      ),
                    ),
                    _buildStepIcon(isPast: isPast, isCurrent: isCurrent, isDark: isDark),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isLast
                            ? Colors.transparent
                            : (stepNum < progressStage
                                ? AppColors.brandYellow
                                : (isDark ? AppColors.darkBorder : AppColors.border)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: isCurrent || isPast ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent || isPast
                        ? (isDark ? Colors.white : AppColors.slateDark)
                        : AppColors.inkFaint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['subtitle'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepIcon({
    required bool isPast,
    required bool isCurrent,
    required bool isDark,
  }) {
    if (isPast) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.brandYellow,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 13, color: AppColors.slateDark),
      );
    }
    if (isCurrent) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.brandYellow,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.local_shipping, size: 12, color: AppColors.slateDark),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDriverAndTruckCards(BookingItem b, bool isDark) {
    final hasDriver = b.driverName != null &&
        b.driverName!.trim().isNotEmpty &&
        b.driverName != 'Assigning Driver...';
    final isPendingPartner = !hasDriver;
    final driverName = hasDriver ? b.driverName! : 'Assigning Driver...';
    final hasPhone = b.driverPhone != null && b.driverPhone!.trim().isNotEmpty;
    final truckType = b.cargoType.isNotEmpty ? b.cargoType : 'Tata 407 (Commercial)';
    final truckReg = b.truckReg != null && b.truckReg!.isNotEmpty ? b.truckReg! : 'Corridor Search';

    if (isPendingPartner) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: AppColors.slateDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Matching Verified Truck Partner...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slateDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Corridor: ${b.origin} → ${b.destination}\nNearby commercial truckers on this route are being notified.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? AppColors.darkInkMuted : AppColors.inkMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.brandYellow,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            // Left: Driver Details Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/driver_avatar_default.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const CircleAvatar(
                          radius: 19,
                          backgroundColor: Color(0xFFFEF3C7),
                          child: Icon(Icons.person, color: AppColors.slateDark, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.slateDark,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 11, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Text(
                                '4.8 (320)',
                                style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                          Text(
                            'Your Driver',
                            style: GoogleFonts.inter(fontSize: 9, color: AppColors.inkFaint),
                          ),
                        ],
                      ),
                    ),
                    if (hasPhone) ...[
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('tel:${b.driverPhone}')),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                          child: Icon(
                            Icons.phone,
                            size: 13,
                            color: isDark ? Colors.white : AppColors.slateDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Right: Vehicle Details Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/tracking_vehicle_thumb.png',
                        width: 36,
                        height: 26,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.local_shipping,
                          size: 24,
                          color: AppColors.brandYellow,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            truckType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.slateDark,
                            ),
                          ),
                          Text(
                            truckReg,
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Direct In-App Chat Button
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DirectChatScreen(
                    bookingId: b.id,
                    counterpartyName: driverName,
                    counterpartyRole: 'driver',
                    counterpartyPhone: b.driverPhone ?? '+91 98765 43210',
                    origin: b.origin,
                    destination: b.destination,
                    truckReg: b.truckReg,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: Text(
              'Chat with Driver ($driverName)',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnTimeBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.of(context, 'onTime'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slateDark,
                    ),
                  ),
                  Text(
                    'Your shipment is moving as per schedule.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            'Moving\nIndia Forward →',
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white : AppColors.slateDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BookingItem b, bool isDark) {
    return Column(
      children: [
        if (b.pickupOtp != null && ['confirmed', 'pickup_ready'].contains(b.status)) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
              border: Border.all(
                color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
              ),
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
                      Text(
                        'Pickup Verification OTP',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: isDark ? Colors.white : AppColors.slateDark,
                        ),
                      ),
                      Text(
                        'Share OTP with driver upon arrival.',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  b.pickupOtp!,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: isDark ? AppColors.brandYellow : AppColors.slateDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_loading)
          const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
        else if (_events.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestone Log',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slateDark,
                  ),
                ),
                const SizedBox(height: 8),
                ..._events.reversed.take(3).map((e) {
                  final date = DateTime.tryParse('${e['timestamp'] ?? ''}')?.toLocal();
                  final timeStr = date != null ? DateFormat('d MMM, h:mm a').format(date) : 'Recent';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e['description'] ?? 'GPS Ping',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.slateDark,
                            ),
                          ),
                        ),
                        Text(timeStr, style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        TextButton.icon(
          onPressed: () {
            setState(() {
              _selected = null;
              _events = [];
            });
          },
          icon: const Icon(Icons.swap_horiz, size: 16),
          label: Text(
            'Track a different booking',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateOrSelector(ShipmentsViewModel vm, bool isDark) {
    if (vm.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (vm.shipments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
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
                Icons.location_searching_rounded,
                size: 40,
                color: AppColors.slateDark,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Active Shipment to Track',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slateDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your Booking ID or LR Number in the search bar above, or book a commercial truck to see live GPS tracking here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                widget.onTabChangeRequested?.call(0);
              },
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a booking to track',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.slateDark,
          ),
        ),
        const SizedBox(height: 10),
        ...vm.shipments.map((b) {
          final idShort = b.id.substring(0, b.id.length > 8 ? 8 : b.id.length).toUpperCase();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selected = b;
                  _searchController.text = idShort;
                });
                _initTrackingForSelected();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_shipping, color: AppColors.slateDark, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${b.origin} → ${b.destination}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isDark ? Colors.white : AppColors.slateDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#$idShort • ${b.cargoType} • ${b.weightTons.toStringAsFixed(1)} T',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: b.status),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
