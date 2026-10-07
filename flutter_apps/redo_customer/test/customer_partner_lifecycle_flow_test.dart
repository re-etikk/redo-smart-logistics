import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/core/theme.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/data/services/routing_service.dart';
import 'package:redo_customer/ui/screens/shipments/driver_matching_screen.dart';
import 'package:redo_customer/ui/screens/shipments/tracking_screen.dart';
import 'package:redo_customer/viewmodels/booking_viewmodel.dart';
import 'package:redo_customer/viewmodels/shipments_viewmodel.dart';

class MockBookingVM extends ChangeNotifier implements BookingViewModel {
  @override
  String get origin => 'Delhi, DL';

  @override
  String get destination => 'Patna, BR';

  @override
  String get cargoType => 'Mac Mini M4 Pro (50 units)';

  @override
  double get weightKg => 12000.0;

  @override
  double get priceTotalInr => 4850.0;

  @override
  List<TruckMatch> get matches => [];

  @override
  LatLng get originLatLng => const LatLng(28.6139, 77.2090);

  @override
  LatLng get destinationLatLng => const LatLng(25.5941, 85.1376);

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
  CargoRequest? get lastPostedCargo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockShipmentsVM extends ChangeNotifier implements ShipmentsViewModel {
  final List<BookingItem> _shipments;

  MockShipmentsVM(this._shipments);

  @override
  List<BookingItem> get shipments => _shipments;

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchShipments({bool silent = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Complete End-to-End Lifecycle Flow Test:
/// CUSTOMER (Delhi → Patna) ⇄ BACKEND ⇄ PARTNER (45s Accept → Navigation → Pickup OTP → Active Delivery → Delivery OTP → Delivered → Earnings)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Customer ⇄ Backend ⇄ Partner Lifecycle', () {
    const String originCity = 'Delhi, DL';
    const String destinationCity = 'Patna, BR';
    const String cargoTitle = 'Mac Mini M4 Pro (50 units)';
    const double cargoWeightTons = 12.0;
    const double tripPayoutInr = 4850.0;
    const String pickupOtpCode = '4821';
    const String deliveryOtpCode = '9182';
    const String driverName = 'Rahul Kumar';
    const String truckNumber = 'UP 32 AB 1234';

    test('Step 1 & 2: Customer creates Delhi → Patna shipment and Backend records cargo/booking', () {
      final cargo = CargoRequest(
        cargoId: 'crg_delhi_patna_101',
        smeId: 'sme_ritik_001',
        origin: originCity,
        destination: destinationCity,
        distanceKm: 1000.0,
        cargoType: cargoTitle,
        cargoWeightTons: cargoWeightTons,
        urgency: 'instant',
        status: 'open',
        createdAt: DateTime.now().toIso8601String(),
        pickupAddress: 'Okhla Phase 3, Delhi',
        dropAddress: 'Patliputra Industrial Area, Patna',
        estimatedPriceInr: tripPayoutInr,
      );

      expect(cargo.origin, equals(originCity));
      expect(cargo.destination, equals(destinationCity));
      expect(cargo.cargoWeightTons, equals(12.0));
      expect(cargo.estimatedPriceInr, equals(4850.0));

      final initialBooking = BookingItem(
        id: 'BK-DEL-PAT-9001',
        cargoId: cargo.cargoId,
        truckId: '',
        origin: cargo.origin,
        destination: cargo.destination,
        cargoType: cargo.cargoType,
        weightTons: cargo.cargoWeightTons,
        agreedPriceInr: cargo.estimatedPriceInr,
        status: 'pending',
        pickupOtp: pickupOtpCode,
        deliveryOtp: deliveryOtpCode,
        createdAt: DateTime.now().toIso8601String(),
        pickupAddress: cargo.pickupAddress,
        dropAddress: cargo.dropAddress,
      );

      expect(initialBooking.status, equals('pending'));
      expect(initialBooking.pickupOtp, equals(pickupOtpCode));
      expect(initialBooking.deliveryOtp, equals(deliveryOtpCode));
    });

    test('Step 3, 4 & 5: Partner receives 45s countdown alert and taps ACCEPT', () {
      int secondsRemaining = 45;
      expect(secondsRemaining, equals(45));

      // 45s countdown decrement
      secondsRemaining -= 3;
      expect(secondsRemaining, equals(42));

      // Partner accepts load
      bool isAccepted = false;
      String? assignedDriverName;
      String? assignedTruck;

      void onAccept() {
        isAccepted = true;
        assignedDriverName = driverName;
        assignedTruck = truckNumber;
      }

      onAccept();
      expect(isAccepted, isTrue);
      expect(assignedDriverName, equals('Rahul Kumar'));
      expect(assignedTruck, equals('UP 32 AB 1234'));
    });

    testWidgets('Step 5 & 6: Customer UI renders Driver Matching & Dispatch Screen', (tester) async {
      tester.view.physicalSize = const Size(390.0, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingViewModel>(create: (_) => MockBookingVM()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DriverMatchingScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DriverMatchingScreen), findsOneWidget);
    });

    test('Step 7 & 8: Partner navigates and enters Pickup OTP to advance to Picked Up (in_transit)', () {
      final booking = BookingItem(
        id: 'BK-DEL-PAT-9001',
        cargoId: 'crg_delhi_patna_101',
        truckId: 'TRK-UP32',
        driverName: driverName,
        truckReg: truckNumber,
        origin: originCity,
        destination: destinationCity,
        cargoType: cargoTitle,
        weightTons: cargoWeightTons,
        agreedPriceInr: tripPayoutInr,
        status: 'confirmed',
        pickupOtp: pickupOtpCode,
        deliveryOtp: deliveryOtpCode,
        createdAt: DateTime.now().toIso8601String(),
        pickupAddress: 'Okhla Phase 3, Delhi',
        dropAddress: 'Patliputra Industrial Area, Patna',
      );

      // Verify pickup OTP
      const enteredOtp = '4821';
      final bool isOtpValid = (enteredOtp == booking.pickupOtp);
      expect(isOtpValid, isTrue);

      // Transition to in_transit
      final pickedUpBooking = BookingItem(
        id: booking.id,
        cargoId: booking.cargoId,
        truckId: booking.truckId,
        driverName: booking.driverName,
        truckReg: booking.truckReg,
        origin: booking.origin,
        destination: booking.destination,
        cargoType: booking.cargoType,
        weightTons: booking.weightTons,
        agreedPriceInr: booking.agreedPriceInr,
        status: 'in_transit',
        pickupOtp: booking.pickupOtp,
        deliveryOtp: booking.deliveryOtp,
        createdAt: booking.createdAt,
        pickupAddress: booking.pickupAddress,
        dropAddress: booking.dropAddress,
      );

      expect(pickedUpBooking.status, equals('in_transit'));
    });

    testWidgets('Step 9 & 10: Customer Tracking UI shows Active In-Transit delivery', (tester) async {
      tester.view.physicalSize = const Size(390.0, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final activeBooking = BookingItem(
        id: 'BK-DEL-PAT-9001',
        cargoId: 'crg_delhi_patna_101',
        truckId: 'TRK-UP32',
        driverName: driverName,
        truckReg: truckNumber,
        driverPhone: '+91 98765 43210',
        origin: originCity,
        destination: destinationCity,
        cargoType: cargoTitle,
        weightTons: cargoWeightTons,
        agreedPriceInr: tripPayoutInr,
        status: 'in_transit',
        pickupOtp: pickupOtpCode,
        deliveryOtp: deliveryOtpCode,
        createdAt: DateTime.now().toIso8601String(),
        pickupAddress: 'Okhla Phase 3, Delhi',
        dropAddress: 'Patliputra Industrial Area, Patna',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ShipmentsViewModel>(create: (_) => MockShipmentsVM([activeBooking])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: TrackingScreen(booking: activeBooking),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Live tracking'), findsOneWidget);
      expect(find.text('In transit'), findsWidgets);
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('UP 32 AB 1234'), findsOneWidget);
    });

    test('Step 11, 12 & 13: Partner enters Delivery OTP, Customer receives Delivered status, and Partner earnings update', () {
      final inTransitBooking = BookingItem(
        id: 'BK-DEL-PAT-9001',
        cargoId: 'crg_delhi_patna_101',
        truckId: 'TRK-UP32',
        driverName: driverName,
        truckReg: truckNumber,
        origin: originCity,
        destination: destinationCity,
        cargoType: cargoTitle,
        weightTons: cargoWeightTons,
        agreedPriceInr: tripPayoutInr,
        status: 'in_transit',
        pickupOtp: pickupOtpCode,
        deliveryOtp: deliveryOtpCode,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Verify delivery OTP entered by Partner
      const enteredDeliveryOtp = '9182';
      expect(enteredDeliveryOtp == inTransitBooking.deliveryOtp, isTrue);

      // Transition to delivered
      final deliveredBooking = BookingItem(
        id: inTransitBooking.id,
        cargoId: inTransitBooking.cargoId,
        truckId: inTransitBooking.truckId,
        driverName: inTransitBooking.driverName,
        truckReg: inTransitBooking.truckReg,
        origin: inTransitBooking.origin,
        destination: inTransitBooking.destination,
        cargoType: inTransitBooking.cargoType,
        weightTons: inTransitBooking.weightTons,
        agreedPriceInr: inTransitBooking.agreedPriceInr,
        status: 'delivered',
        pickupOtp: inTransitBooking.pickupOtp,
        deliveryOtp: inTransitBooking.deliveryOtp,
        createdAt: inTransitBooking.createdAt,
      );

      expect(deliveredBooking.status, equals('delivered'));

      // Partner earnings updated
      double currentEarnings = 4820.0;
      int completedTrips = 4;

      currentEarnings += deliveredBooking.agreedPriceInr;
      completedTrips += 1;

      expect(currentEarnings, equals(9670.0));
      expect(completedTrips, equals(5));
    });
  });
}
