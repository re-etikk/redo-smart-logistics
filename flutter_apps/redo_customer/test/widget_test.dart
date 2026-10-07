import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/core/theme.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/data/services/routing_service.dart';
import 'package:redo_customer/ui/screens/home/home_screen.dart';
import 'package:redo_customer/ui/screens/shipments/cargo_details_screen.dart';
import 'package:redo_customer/ui/screens/shipments/create_shipment_screen.dart';
import 'package:redo_customer/ui/screens/shipments/driver_matching_screen.dart';
import 'package:redo_customer/ui/screens/shipments/price_estimate_screen.dart';
import 'package:redo_customer/viewmodels/auth_viewmodel.dart';
import 'package:redo_customer/viewmodels/booking_viewmodel.dart';
import 'package:redo_customer/viewmodels/shipments_viewmodel.dart';

class MockAuthViewModel extends ChangeNotifier implements AuthViewModel {
  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  UserProfile? get profile => UserProfile(
        id: 'test-user',
        fullName: 'Ritik Sharma',
        role: 'customer',
        onboardingComplete: true,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockShipmentsViewModel extends ChangeNotifier implements ShipmentsViewModel {
  @override
  List<BookingItem> get shipments => [];

  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockBookingViewModel extends ChangeNotifier implements BookingViewModel {
  @override
  String get origin => 'Delhi, DL';

  @override
  String get destination => 'Patna, BR';

  @override
  String get cargoType => 'Electronics';

  @override
  double get weightKg => 12.0;

  @override
  double get weightTons => 0.012;

  @override
  double get volumetricWeightTons => 0.012;

  @override
  double get billableWeightTons => 0.012;

  @override
  double get volumeCft => 0.32;

  @override
  int get packageCount => 2;

  @override
  double get lengthCm => 30.0;

  @override
  double get widthCm => 20.0;

  @override
  double get heightCm => 15.0;

  @override
  bool get isFragile => false;

  @override
  bool get isTemperatureSensitive => false;

  @override
  double get declaredValueInr => 50000.0;

  @override
  double get roadDistanceKm => 1050.0;

  @override
  double get priceBaseFareInr => 2200.0;

  @override
  double get priceDistanceChargeInr => 420.0;

  @override
  double get priceCargoHandlingInr => 180.0;

  @override
  double get priceServiceFeeInr => 50.0;

  @override
  double get priceTotalInr => 2850.0;

  @override
  bool get isRouting => false;

  @override
  List<TruckMatch> get matches => [];

  @override
  PlaceSuggestion get originPlace => PlaceSuggestion(
        name: 'Delhi, DL',
        description: 'New Delhi Logistics Hub',
        latLng: const LatLng(28.6139, 77.2090),
      );

  @override
  PlaceSuggestion get destPlace => PlaceSuggestion(
        name: 'Patna, BR',
        description: 'Patna Transport Nagar',
        latLng: const LatLng(25.5941, 85.1376),
      );

  @override
  LatLng get originLatLng => const LatLng(28.6139, 77.2090);

  @override
  LatLng get destinationLatLng => const LatLng(25.5941, 85.1376);

  @override
  void setOriginPlace(PlaceSuggestion place) {}

  @override
  void setDestinationPlace(PlaceSuggestion place) {}

  @override
  void setCargoType(String type) {}

  @override
  void setWeightKg(double kg) {}

  @override
  void setPackageCount(int count) {}

  @override
  void setDimensions({required double length, required double width, required double height}) {}

  @override
  void setFragile(bool val) {}

  @override
  void setTemperatureSensitive(bool val) {}

  @override
  void setDeclaredValueInr(double val) {}

  @override
  Future<bool> searchMatchingTrucks() async => true;

  @override
  Future<CargoRequest?> createShipmentOrder({double? estimatedPrice}) async => CargoRequest(
    cargoId: 'CR-TEST-99',
    smeId: 'sme-1',
    origin: origin,
    destination: destination,
    distanceKm: roadDistanceKm,
    cargoType: cargoType,
    cargoWeightTons: weightKg / 1000.0,
    urgency: 'normal',
    status: 'open',
    createdAt: DateTime.now().toIso8601String(),
    estimatedPriceInr: priceTotalInr,
  );

  PriceQuote? get priceQuote => const PriceQuote(
        estimatedPriceInr: 2800.0,
        finalPriceInr: 2850.0,
        applicableFeesInr: 50.0,
        savingsAmountInr: 450.0,
        savingsPct: 15,
        estimatedDedicatedTruckPriceInr: 3300.0,
        conditions: PricingConditions(
          corridorId: 'corridor-del-pat',
          corridorName: 'Delhi to Patna Backhaul Lane',
          baseRatePerTonKm: 2.8,
          minFareInr: 1200.0,
          cargoTypeMultiplier: 1.0,
          surgeMultiplier: 1.0,
          demandCount: 5,
          supplyCount: 8,
          billableWeightTons: 0.12,
          actualWeightTons: 0.12,
          urgency: 'normal',
        ),
      );

  @override
  bool get isFetchingQuote => false;

  bool get isCalculatingPrice => false;

  @override
  PriceQuote? get currentQuote => priceQuote;

  @override
  double get savingsAmountInr => 450.0;

  @override
  int get savingsPct => 15;

  @override
  double get dedicatedTruckBenchmarkInr => 3300.0;

  @override
  PricingConditions? get pricingConditions => priceQuote?.conditions;

  @override
  Future<PriceQuote> fetchPriceQuote({bool silent = false}) async => priceQuote!;

  @override
  Future<bool> retryDispatch() async => true;

  @override
  Future<bool> cancelCurrentCargo() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End Navigation: Home -> Create -> Cargo -> Price -> Matching',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>(create: (_) => MockAuthViewModel()),
          ChangeNotifierProvider<ShipmentsViewModel>(create: (_) => MockShipmentsViewModel()),
          ChangeNotifierProvider<BookingViewModel>(create: (_) => MockBookingViewModel()),
        ],
        child: MaterialApp(
          theme: ReDoTheme.lightTheme,
          home: HomeScreen(
            onCreateShipment: () {},
          ),
          routes: {
            '/create': (_) => const CreateShipmentScreen(),
            '/cargo': (_) => const CargoDetailsScreen(),
            '/price': (_) => const PriceEstimateScreen(),
            '/matching': (_) => const DriverMatchingScreen(),
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Home Screen loaded
    expect(find.text('Send a shipment'), findsOneWidget);
    expect(find.text('Live shipment'), findsOneWidget);

    // 2. Pump Screen 02: Create Shipment
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookingViewModel>(create: (_) => MockBookingViewModel()),
        ],
        child: MaterialApp(
          theme: ReDoTheme.lightTheme,
          home: const CreateShipmentScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Create shipment'), findsOneWidget);
    expect(find.text('Where is it going?'), findsOneWidget);
    expect(find.text('What are you sending?'), findsOneWidget);

    // 3. Pump Screen 03: Cargo Details
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookingViewModel>(create: (_) => MockBookingViewModel()),
        ],
        child: MaterialApp(
          theme: ReDoTheme.lightTheme,
          home: const CargoDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cargo details'), findsOneWidget);
    expect(find.text('How heavy is it?'), findsOneWidget);
    expect(find.text('Package dimensions'), findsOneWidget);

    // 4. Pump Screen 04: Price Estimate
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookingViewModel>(create: (_) => MockBookingViewModel()),
        ],
        child: MaterialApp(
          theme: ReDoTheme.lightTheme,
          home: const PriceEstimateScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Price estimate'), findsOneWidget);
    expect(find.text('Estimated delivery cost'), findsOneWidget);
    expect(find.text('Price breakdown'), findsOneWidget);

    // 5. Pump Screen 05: Driver Matching
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookingViewModel>(create: (_) => MockBookingViewModel()),
        ],
        child: MaterialApp(
          theme: ReDoTheme.lightTheme,
          home: const DriverMatchingScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Finding your driver'), findsOneWidget);
    expect(find.text('Searching nearby partners'), findsOneWidget);
    expect(find.text('Shipment details'), findsOneWidget);
  });
}
