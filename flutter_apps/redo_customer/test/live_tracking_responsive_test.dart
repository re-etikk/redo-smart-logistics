import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/core/theme.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/ui/screens/shipments/shipment_details_screen.dart';
import 'package:redo_customer/ui/screens/shipments/tracking_screen.dart';
import 'package:redo_customer/viewmodels/shipments_viewmodel.dart';

class MockShipmentsViewModel extends ChangeNotifier implements ShipmentsViewModel {
  @override
  List<BookingItem> get shipments => [
        BookingItem(
          id: '314315796',
          cargoId: 'CRG-9021',
          truckId: 'TRK-441',
          origin: 'Delhi, DL',
          destination: 'Patna, BR',
          cargoType: 'Mac Mini M4 Pro',
          weightTons: 0.0124,
          agreedPriceInr: 2850.0,
          status: 'in_transit',
          createdAt: '2026-10-05T10:20:00Z',
          driverName: 'Rahul Kumar',
          driverPhone: '+91 98765 43210',
          truckReg: 'UP 32 AB 1234',
        ),
      ];

  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const deviceWidths = [
    360.0, // Small Android
    375.0, // iPhone SE / Mini
    390.0, // iPhone 12/13/14
    393.0, // Pixel 7
    412.0, // Samsung Galaxy / Pixel Pro
    428.0, // iPhone 14 Pro Max
  ];

  for (final width in deviceWidths) {
    testWidgets('Screen 06 — Live Tracking renders with zero overflow on ${width.toInt()}px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(width, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockVM = MockShipmentsViewModel();
      final testBooking = mockVM.shipments.first;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ShipmentsViewModel>.value(value: mockVM),
          ],
          child: MaterialApp(
            theme: ReDoTheme.lightTheme,
            home: TrackingScreen(booking: testBooking),
          ),
        ),
      );
      await tester.pump();

      // 1. Verify Top Floating Header Bar
      expect(find.text('Live tracking'), findsOneWidget);
      expect(find.text('RD-314315796'), findsOneWidget);
      expect(find.text('In Transit'), findsWidgets);

      // 2. Verify Bottom Sheet Cargo Summary
      expect(find.text('Mac Mini M4 Pro'), findsOneWidget);
      expect(find.text('ID: H314315796'), findsOneWidget);
      expect(find.text('ETA'), findsOneWidget);
      expect(find.text('4h 20m'), findsOneWidget);
      expect(find.text('Distance remaining'), findsOneWidget);
      expect(find.text('540 km'), findsOneWidget);

      // 3. Verify 3-Stage Route Progression Timeline
      expect(find.text('Pickup'), findsOneWidget);
      expect(find.text('In transit'), findsWidgets);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('On the way'), findsOneWidget);
      expect(find.text('68 km/h'), findsWidgets);

      // 4. Verify Driver & Vehicle Profile
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('Verified Partner'), findsOneWidget);
      expect(find.text('Tata 14T'), findsOneWidget);
      expect(find.text('UP 32 AB 1234'), findsOneWidget);

      // 5. Verify Action Buttons
      expect(find.text('Call Driver'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('View shipment details'), findsOneWidget);

      // 6. Test interaction: tap "View shipment details" and verify navigation
      await tester.tap(find.text('View shipment details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ShipmentDetailsScreen), findsOneWidget);
    });
  }
}
