import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../screens/dispatch/incoming_trip_request_screen.dart';

/// Overlay wrapper that displays the native IncomingTripRequestScreen (Screen 02)
/// whenever a real dispatch offer is received from the backend.
class InstantLoadDispatchSheet extends StatelessWidget {
  final AvailableLoad load;
  final int secondsRemaining;
  final Future<void> Function() onAccept;
  final VoidCallback onDecline;

  const InstantLoadDispatchSheet({
    super.key,
    required this.load,
    required this.secondsRemaining,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return IncomingTripRequestScreen(
      load: load,
      secondsRemaining: secondsRemaining,
      onAccept: onAccept,
      onDecline: onDecline,
    );
  }
}
