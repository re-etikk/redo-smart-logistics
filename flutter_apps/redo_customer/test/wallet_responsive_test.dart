import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/core/theme.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/ui/screens/wallet/wallet_screen.dart';
import 'package:redo_customer/ui/screens/shipments/shipment_details_screen.dart';
import 'package:redo_customer/viewmodels/shipments_viewmodel.dart';

class MockShipmentsViewModel extends ChangeNotifier implements ShipmentsViewModel {
  @override
  List<BookingItem> get shipments => [];
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
    testWidgets('Screen 09 — Wallet renders with zero overflow on ${vp.width.toInt()}x${vp.height.toInt()}', (tester) async {
      tester.view.physicalSize = vp;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<ShipmentsViewModel>(
            create: (_) => MockShipmentsViewModel(),
            child: const WalletScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure no exceptions or render overflows
      expect(tester.takeException(), isNull);

      // Verify Header
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Manage your ReDo payments and credits.'), findsOneWidget);

      // Verify Available Balance Card
      expect(find.text('Available balance'), findsOneWidget);
      expect(find.text('₹2,450'), findsOneWidget);
      expect(find.text('Add money'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);

      // Verify ReDo Credits Card
      expect(find.text('ReDo credits'), findsAtLeastNWidgets(1));
      expect(find.text('₹200 available'), findsOneWidget);
      expect(find.text('View details'), findsOneWidget);

      // Verify Payment Methods Section
      expect(find.text('Payment methods'), findsOneWidget);
      expect(find.text('UPI'), findsAtLeastNWidgets(1));
      expect(find.text('Mastercard'), findsOneWidget);
      expect(find.text('Manage payment methods'), findsOneWidget);
    });
  }

  testWidgets('Screen 09 — "Add money" opens interactive bottom sheet and adds money', (tester) async {
    tester.view.physicalSize = const Size(390.0, 844.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ShipmentsViewModel>(
          create: (_) => MockShipmentsViewModel(),
          child: const WalletScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final addMoneyButton = find.text('Add money');
    expect(addMoneyButton, findsOneWidget);
    await tester.tap(addMoneyButton);
    await tester.pumpAndSettle();

    // Verify Add Money modal content
    expect(find.text('Add money to wallet'), findsOneWidget);
    expect(find.text('Select payment method'), findsOneWidget);
    expect(find.text('+ ₹500'), findsOneWidget);

    // Tap quick chip + ₹2000
    await tester.tap(find.text('+ ₹2000'));
    await tester.pumpAndSettle();

    // Tap Proceed to add money
    final proceedBtn = find.text('Proceed to add money');
    expect(proceedBtn, findsOneWidget);
    await tester.tap(proceedBtn);
    await tester.pumpAndSettle();

    // Modal should close and balance update: 2450 + 2000 = 4450
    expect(find.text('₹4,450'), findsOneWidget);
  });

  testWidgets('Screen 09 — "View details" on ReDo credits opens credits bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(390.0, 844.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ShipmentsViewModel>(
          create: (_) => MockShipmentsViewModel(),
          child: const WalletScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final viewDetailsBtn = find.text('View details');
    expect(viewDetailsBtn, findsOneWidget);
    await tester.tap(viewDetailsBtn);
    await tester.pumpAndSettle();

    expect(find.text('ReDo Promotional Credits'), findsOneWidget);
    expect(find.text('How credits work:'), findsOneWidget);

    // Close modal
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('How credits work:'), findsNothing);
  });

  testWidgets('Screen 09 — Tapping a shipment activity navigates to ShipmentDetailsScreen', (tester) async {
    tester.view.physicalSize = const Size(390.0, 900.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ShipmentsViewModel>(
          create: (_) => MockShipmentsViewModel(),
          child: const WalletScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to activity item
    final activityItem = find.text('Mac Mini M4 Pro • Delhi → Patna');
    await tester.ensureVisible(activityItem);
    await tester.pumpAndSettle();

    expect(activityItem, findsOneWidget);
    await tester.tap(activityItem);
    await tester.pumpAndSettle();

    // Should navigate to ShipmentDetailsScreen
    expect(find.byType(ShipmentDetailsScreen), findsOneWidget);
  });
}
