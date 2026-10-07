import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/core/theme.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/ui/screens/shipments/price_estimate_screen.dart';
import 'package:redo_customer/viewmodels/booking_viewmodel.dart';

class TestBookingViewModel extends ChangeNotifier implements BookingViewModel {
  @override
  String get origin => 'Delhi, DL';

  @override
  String get destination => 'Patna, BR';

  @override
  String get cargoType => 'Electronics';

  @override
  double get weightKg => 12.0;

  @override
  int get packageCount => 2;

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

  @override
  double get weightTons => weightKg / 1000.0;

  @override
  double get volumetricWeightTons => 0.012;

  @override
  double get billableWeightTons => 0.012;

  @override
  double get volumeCft => 0.32;

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
    testWidgets('PriceEstimateScreen renders with 0 errors/overflow at ${size.width}x${size.height}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingViewModel>(
              create: (_) => TestBookingViewModel(),
            ),
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
      expect(find.text('Pricing conditions'), findsOneWidget);
      expect(find.text('Confirm shipment'), findsOneWidget);
      expect(find.text('Edit shipment'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }
}
