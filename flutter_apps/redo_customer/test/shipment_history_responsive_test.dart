import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/ui/screens/shipments/shipments_screen.dart';
import 'package:redo_customer/ui/screens/shipments/shipment_details_screen.dart';
import 'package:redo_customer/viewmodels/shipments_viewmodel.dart';

class MockShipmentsViewModel extends ChangeNotifier implements ShipmentsViewModel {
  final List<BookingItem> _mockShipments = [
    BookingItem(
      id: 'H314315796',
      cargoId: 'H314315796',
      truckId: 'TRK-UP32AB1234',
      origin: 'Delhi, DL',
      destination: 'Patna, BR',
      cargoType: 'Mac Mini M4 Pro',
      weightTons: 0.012,
      agreedPriceInr: 2850,
      status: 'in_transit',
      createdAt: '2026-10-05T10:20:00Z',
    ),
    BookingItem(
      id: 'H204859123',
      cargoId: 'H204859123',
      truckId: 'TRK-DL01CD5678',
      origin: 'Lucknow, UP',
      destination: 'Delhi, DL',
      cargoType: 'Industrial Electronics',
      weightTons: 0.450,
      agreedPriceInr: 1920,
      status: 'delivered',
      createdAt: '2026-09-12T09:15:00Z',
    ),
    BookingItem(
      id: 'H194827561',
      cargoId: 'H194827561',
      truckId: 'TRK-RJ14EF9012',
      origin: 'Kanpur, UP',
      destination: 'Jaipur, RJ',
      cargoType: 'Assorted Packages',
      weightTons: 0.220,
      agreedPriceInr: 2350,
      status: 'cancelled',
      createdAt: '2026-09-08T11:30:00Z',
    ),
  ];

  @override
  List<BookingItem> get shipments => _mockShipments;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> fetchShipments({bool silent = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final targetViewports = [
    const Size(360.0, 800.0),
    const Size(375.0, 812.0),
    const Size(390.0, 844.0),
    const Size(393.0, 852.0),
    const Size(412.0, 915.0),
    const Size(428.0, 926.0),
  ];

  for (final vp in targetViewports) {
    testWidgets('Screen 08 — Shipment History renders with zero overflow on ${vp.width.toInt()}x${vp.height.toInt()}', (tester) async {
      tester.view.physicalSize = vp;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ShipmentsViewModel>(
            create: (_) => MockShipmentsViewModel(),
            child: const ShipmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure no exceptions or render overflows
      expect(tester.takeException(), isNull);

      // Verify Header
      expect(find.text('Your shipments'), findsOneWidget);
      expect(find.text('Track and manage all your deliveries.'), findsOneWidget);

      // Verify Search bar
      expect(find.byType(TextField), findsOneWidget);

      // Verify Filter Pills
      expect(find.textContaining('All'), findsAtLeastNWidgets(1));
      expect(find.textContaining('In Transit'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Delivered'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Cancelled'), findsAtLeastNWidgets(1));

      // Verify Shipment card content
      expect(find.text('Mac Mini M4 Pro'), findsOneWidget);
    });
  }

  testWidgets('Screen 08 — Shipment History search and filter pills work accurately', (tester) async {
    tester.view.physicalSize = const Size(390.0, 844.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ShipmentsViewModel>(
          create: (_) => MockShipmentsViewModel(),
          child: const ShipmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial State: cards are present
    expect(find.text('Mac Mini M4 Pro'), findsOneWidget);
    expect(find.text('Industrial Electronics'), findsOneWidget);

    // 2. Tap on "Delivered" tab
    final deliveredPill = find.text('Delivered (1)');
    expect(deliveredPill, findsOneWidget);
    await tester.ensureVisible(deliveredPill);
    await tester.tap(deliveredPill);
    await tester.pumpAndSettle();

    // Should only show delivered items
    expect(find.text('Industrial Electronics'), findsOneWidget);
    expect(find.text('Mac Mini M4 Pro'), findsNothing);

    // 3. Tap on "All" tab
    final allPill = find.text('All (3)');
    await tester.ensureVisible(allPill);
    await tester.tap(allPill);
    await tester.pumpAndSettle();
    expect(find.text('Mac Mini M4 Pro'), findsOneWidget);

    // 4. Search query test
    await tester.enterText(find.byType(TextField), 'Mac Mini');
    await tester.pumpAndSettle();
    expect(find.text('Mac Mini M4 Pro'), findsOneWidget);
    expect(find.text('Industrial Electronics'), findsNothing);

    // 5. Reset query
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Industrial Electronics'), findsOneWidget);
  });

  testWidgets('Screen 08 — Shipment card tap navigates to ShipmentDetailsScreen', (tester) async {
    tester.view.physicalSize = const Size(390.0, 844.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ShipmentsViewModel>(
          create: (_) => MockShipmentsViewModel(),
          child: const ShipmentsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the shipment card containing 'Mac Mini M4 Pro' and tap it
    final cardFinder = find.text('Mac Mini M4 Pro');
    expect(cardFinder, findsOneWidget);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Should push ShipmentDetailsScreen
    expect(find.byType(ShipmentDetailsScreen), findsOneWidget);
  });
}
