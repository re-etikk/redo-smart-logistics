import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/core/theme.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/ui/screens/home/home_screen.dart';
import 'package:redo_customer/ui/widgets/redo_design_system.dart';
import 'package:redo_customer/viewmodels/auth_viewmodel.dart';
import 'package:redo_customer/viewmodels/shipments_viewmodel.dart';

// Test stub for AuthViewModel
class TestAuthViewModel extends ChangeNotifier implements AuthViewModel {
  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  UserProfile? get profile => UserProfile(
        id: 'test-user-id',
        fullName: 'Ritik Sharma',
        role: 'customer',
        onboardingComplete: true,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// Test stub for ShipmentsViewModel
class TestShipmentsViewModel extends ChangeNotifier implements ShipmentsViewModel {
  @override
  List<BookingItem> get shipments => [
        BookingItem(
          id: 'test-booking-id',
          cargoId: 'cargo-1',
          truckId: 'truck-1',
          origin: 'Delhi',
          destination: 'Patna',
          cargoType: 'Mac Mini M4 Pro',
          weightTons: 0.012,
          agreedPriceInr: 2850,
          status: 'In Transit',
          createdAt: '2026-10-05T00:00:00Z',
        ),
      ];

  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final screenSizes = [
    const Size(360, 640),
    const Size(375, 667),
    const Size(390, 844),
    const Size(393, 852),
    const Size(412, 915),
    const Size(428, 926),
  ];

  for (final size in screenSizes) {
    testWidgets(
      'HomeScreen renders without overflow at ${size.width}x${size.height}',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        FlutterError.onError = (details) {
          debugPrint('>>> OVERFLOW FULL:\n${details.toString()}');
        };
        addTearDown(() => FlutterError.onError = FlutterError.presentError);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>(
                create: (_) => TestAuthViewModel(),
              ),
              ChangeNotifierProvider<ShipmentsViewModel>(
                create: (_) => TestShipmentsViewModel(),
              ),
            ],
            child: MaterialApp(
              theme: ReDoTheme.lightTheme,
              home: Scaffold(
                body: HomeScreen(
                  onTabChangeRequested: (_) {},
                  onCreateShipment: () {},
                ),
                bottomNavigationBar: ReDoBottomNavigation(
                  currentIndex: 0,
                  onTabSelected: (_) {},
                  onCreatePressed: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final exc = tester.takeException();
        if (exc != null) {
          debugPrint('>>> EXCEPTION: $exc');
          if (exc is FlutterError) {
            for (final node in exc.diagnostics) {
              debugPrint('DIAG: ${node.name}: ${node.toDescription()}');
              for (final sub in node.getChildren()) {
                debugPrint('  SUB: ${sub.name}: ${sub.toDescription()}');
              }
            }
          }
        }
        expect(exc, isNull);

        // 2. Verify all UI elements from reference media_1791216686140.png exist
        expect(find.text('Good morning'), findsOneWidget);
        expect(find.text('Send a shipment'), findsOneWidget);
        expect(find.text('Live shipment'), findsOneWidget);
        expect(find.text('Fill empty miles.'), findsOneWidget);
        expect(find.text('History'), findsAtLeastNWidgets(1));
        expect(find.text('Support'), findsAtLeastNWidgets(1));
        expect(find.text('Home'), findsAtLeastNWidgets(1));
        expect(find.text('Shipments'), findsAtLeastNWidgets(1));
        expect(find.text('Create'), findsAtLeastNWidgets(1));
        expect(find.text('Wallet'), findsAtLeastNWidgets(1));
        expect(find.text('Profile'), findsAtLeastNWidgets(1));
      },
    );
  }
}
