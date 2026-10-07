import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';

/// Clean Map UI abstraction for real-time tracking.
/// Encapsulates the interactive map widget, markers, and polyline rendering.
/// Decoupled from tracking business logic and telemetry stream.
class TrackingMapView extends StatefulWidget {
  final LatLng? pickupLocation;
  final LatLng? dropLocation;
  final LatLng? driverLocation;
  final List<LatLng> routePoints;
  final String originCity;
  final String destinationCity;
  final bool isDriverOffline;
  final VoidCallback? onRecenter;

  const TrackingMapView({
    super.key,
    this.pickupLocation,
    this.dropLocation,
    this.driverLocation,
    this.routePoints = const [],
    required this.originCity,
    required this.destinationCity,
    this.isDriverOffline = false,
    this.onRecenter,
  });

  @override
  State<TrackingMapView> createState() => _TrackingMapViewState();
}

class _TrackingMapViewState extends State<TrackingMapView> {
  GoogleMapController? _mapController;

  static const LatLng _indiaDefaultCenter = LatLng(24.5, 80.5);

  @override
  void didUpdateWidget(covariant TrackingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If driver location changed, smooth camera nudge if user is centered
    if (widget.driverLocation != null &&
        oldWidget.driverLocation != widget.driverLocation &&
        _mapController != null) {
      // gentle camera update
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _fitMapToBounds(LatLng p1, LatLng p2) {
    if (_mapController == null) return;
    final south = min(p1.latitude, p2.latitude);
    final north = max(p1.latitude, p2.latitude);
    final west = min(p1.longitude, p2.longitude);
    final east = max(p1.longitude, p2.longitude);

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  void recenter() {
    if (widget.driverLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.driverLocation!, 12),
      );
    } else if (widget.pickupLocation != null && widget.dropLocation != null) {
      _fitMapToBounds(widget.pickupLocation!, widget.dropLocation!);
    }
    widget.onRecenter?.call();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_marker'),
          position: widget.pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup: ${widget.originCity}',
            snippet: 'Origin Loading Point',
          ),
        ),
      );
    }

    if (widget.dropLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop_marker'),
          position: widget.dropLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Delivery: ${widget.destinationCity}',
            snippet: 'Destination Drop Point',
          ),
        ),
      );
    }

    if (widget.driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_marker'),
          position: widget.driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.isDriverOffline ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueOrange,
          ),
          zIndexInt: 10,
          infoWindow: InfoWindow(
            title: widget.isDriverOffline ? 'Driver (Offline)' : 'Moving Truck',
            snippet: 'Current Live GPS Location',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};

    if (widget.routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_corridor'),
          points: widget.routePoints,
          color: const Color(0xFF2563EB),
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    } else if (widget.pickupLocation != null && widget.dropLocation != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_corridor_straight'),
          points: [widget.pickupLocation!, widget.dropLocation!],
          color: const Color(0xFF2563EB),
          width: 4,
          patterns: [PatternItem.dash(18), PatternItem.gap(10)],
        ),
      );
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final initialPos = widget.driverLocation ??
        widget.pickupLocation ??
        _indiaDefaultCenter;

    return Stack(
      children: [
        // Interactive Google Map View (Never a fake static image!)
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPos,
            zoom: 6.5,
          ),
          polylines: _buildPolylines(),
          markers: _buildMarkers(),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
            if (widget.pickupLocation != null && widget.dropLocation != null) {
              _fitMapToBounds(widget.pickupLocation!, widget.dropLocation!);
            }
          },
        ),

        // Floating Map Controls
        Positioned(
          top: 110,
          right: 16,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter on Route',
                  onTap: recenter,
                ),
                const SizedBox(height: 10),
                // Zoom Controls
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.add, size: 20, color: ReDoColors.darkNavy),
                        ),
                      ),
                      Container(height: 1, width: 28, color: const Color(0xFFE5E7EB)),
                      InkWell(
                        onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.remove, size: 20, color: ReDoColors.darkNavy),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Icon(icon, size: 20, color: ReDoColors.darkNavy),
            ),
          ),
        ),
      ),
    );
  }
}
