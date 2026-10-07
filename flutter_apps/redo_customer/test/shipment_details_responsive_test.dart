import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/ui/screens/shipments/shipment_details_screen.dart';
import 'package:redo_customer/viewmodels/shipments_viewmodel.dart';

void main() {
  final targetWidths = [360.0, 375.0, 390.0, 393.0, 412.0, 428.0];

  final sampleBooking = BookingItem(
    id: 'H314315796',
    cargoId: 'H314315796',
    truckId: 'TRK-UP32AB1234',
    origin: 'Delhi, DL',
    destination: 'Patna, BR',
    cargoType: 'Mac Mini M4 Pro',
    weightTons: 0.012, // 12 kg
    agreedPriceInr: 2850,
    status: 'in_transit',
    driverName: 'Rahul Kumar',
    driverPhone: '+91 98765 43210',
    truckReg: 'UP 32 AB 1234',
    createdAt: '2026-10-05T10:20:00Z',
  );

  for (final width in targetWidths) {
    testWidgets('Screen 07 — Shipment Details renders with zero overflow on ${width.toInt()}px width', (tester) async {
      tester.view.physicalSize = Size(width, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ShipmentsViewModel(),
            child: ShipmentDetailsScreen(booking: sampleBooking),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);

      // Verify Screen Title
      expect(find.text('Shipment details'), findsOneWidget);

      // Verify Cargo Name & ID
      expect(find.text('Mac Mini M4 Pro'), findsOneWidget);
      expect(find.text('ID: H314315796'), findsOneWidget);

      // Verify Route & Timeline components
      expect(find.text('Route & timeline'), findsOneWidget);
      expect(find.text('Delhi, DL'), findsAtLeastNWidgets(1));
      expect(find.text('Current location'), findsOneWidget);
      expect(find.text('Patna, BR'), findsAtLeastNWidgets(1));

      // Verify Driver details
      expect(find.text('Driver details'), findsOneWidget);
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('Verified Partner'), findsOneWidget);
      expect(find.text('Call Driver'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);

      // Verify Cargo Information
      expect(find.text('Cargo information'), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('12 kg'), findsOneWidget);

      // Verify Payment Details
      expect(find.text('Payment details'), findsOneWidget);
      expect(find.text('₹2,850'), findsOneWidget);

      // Verify Primary & Secondary Action CTAs
      expect(find.text('Track live'), findsOneWidget);
      expect(find.text('Get help'), findsOneWidget);
    });
  }

  testWidgets('Screen 07 — Shipment Details "Get help" opens bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(390.0, 844.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ShipmentsViewModel(),
          child: ShipmentDetailsScreen(booking: sampleBooking),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final getHelpButton = find.text('Get help');
    expect(getHelpButton, findsOneWidget);
    await tester.ensureVisible(getHelpButton);
    await tester.pumpAndSettle();

    await tester.tap(getHelpButton);
    await tester.pumpAndSettle();

    expect(find.text('ReDo Customer Care & Support'), findsOneWidget);
    expect(find.text('Toll-Free Dispatch Helpline'), findsOneWidget);
  });
}
