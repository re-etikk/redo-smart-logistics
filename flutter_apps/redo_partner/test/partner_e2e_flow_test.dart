import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_partner/core/theme.dart';
import 'package:redo_partner/data/models/models.dart';
import 'package:redo_partner/data/services/corridor_ml_service.dart';
import 'package:redo_partner/ui/screens/home/partner_home_screen.dart';
import 'package:redo_partner/ui/screens/dispatch/incoming_trip_request_screen.dart';
import 'package:redo_partner/ui/screens/dispatch/request_details_screen.dart';
import 'package:redo_partner/ui/screens/trips/accepted_trip_screen.dart';
import 'package:redo_partner/ui/screens/trips/navigation_screen.dart';
import 'package:redo_partner/ui/screens/trips/pickup_verification_screen.dart';
import 'package:redo_partner/ui/screens/trips/active_delivery_screen.dart';
import 'package:redo_partner/ui/screens/trips/delivery_otp_screen.dart';
import 'package:redo_partner/ui/screens/earnings/earnings_screen.dart';
import 'package:redo_partner/ui/screens/profile/profile_screen.dart';
import 'package:redo_partner/viewmodels/auth_viewmodel.dart';
import 'package:redo_partner/viewmodels/partner_trips_viewmodel.dart';
import 'package:redo_partner/viewmodels/theme_viewmodel.dart';

class MockAuthVM extends ChangeNotifier implements AuthViewModel {
  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  DriverProfile? get profile => DriverProfile(
        id: 'driver-999',
        fullName: 'Rahul Kumar',
        phone: '+91 98765 43210',
        role: 'truck_owner',
        companyName: 'Delhi Logistics',
        onboardingComplete: true,
        partnerOnboardingComplete: true,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockPartnerTripsVM extends ChangeNotifier implements PartnerTripsViewModel {
  bool _online = true;

  @override
  bool get isOnline => _online;

  @override
  Future<void> toggleOnlineOffline() async {
    _online = !_online;
    notifyListeners();
  }

  @override
  void setOnlineStatus(bool online) {
    _online = online;
    notifyListeners();
  }

  @override
  double get todayEarningsInr => 4820.0;

  @override
  int get todayTripsCount => 4;

  @override
  double get todayDistanceKm => 286.0;

  @override
  double get driverRating => 4.9;

  @override
  int get instantSecondsLeft => 42;

  @override
  int get instantSecondsRemaining => 42;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  String get searchFilter => '';

  @override
  String get searchFrom => '';

  @override
  String get searchTo => '';

  @override
  bool get myCorridorOnly => false;

  @override
  bool get fillMyCapacityMode => false;

  @override
  String get categoryFilter => 'all';

  @override
  String get tonnageFilter => 'all';

  @override
  double get totalCapacityTons => 14.0;

  @override
  double get bookedCapacityTons => 9.5;

  @override
  double get availableCapacityTons => 4.5;

  @override
  double get capacityUtilizationPct => 67.8;

  @override
  double get potentialExtraEarningsInr => 3200.0;

  @override
  bool get loadingRecommendations => false;

  @override
  Map<String, dynamic>? get nearbyRecommendations => null;

  @override
  List<Map<String, dynamic>> get recommendedCorridors => const [];

  @override
  List<AvailableLoad> get recommendedLoads => const [];

  final ActiveTrip _trip = ActiveTrip(
    bookingId: 'BK-10029',
    cargoId: 'crg_991',
    origin: 'Delhi, DL',
    destination: 'Patna, BR',
    status: 'in_transit',
    payoutInr: 4850.0,
    cargoType: 'Electronics',
    weightTons: 12.0,
    pickupAddress: 'Okhla Phase 3, Delhi',
    dropAddress: 'Patliputra Industrial Area, Patna',
    shipperName: 'Ritik Kumar',
    shipperPhone: '+91 98765 43210',
  );

  @override
  ActiveTrip? get currentActiveTrip => _trip;

  final AvailableLoad _sampleLoad = AvailableLoad(
    cargoId: 'crg_100',
    smeName: 'Apex Electronics',
    origin: 'Delhi, DL',
    destination: 'Patna, BR',
    cargoType: 'Electronics (Mac Mini M4 Pro)',
    weightTons: 12.0,
    offeredPriceInr: 4850.0,
    distanceKm: 1000,
    pickupWindow: 'Pickup in 10 km',
  );

  @override
  AvailableLoad? get instantAlertLoad => _sampleLoad;

  @override
  AvailableLoad? get instantLoadAlert => _sampleLoad;

  @override
  List<AvailableLoad> get availableLoads => [_sampleLoad];

  @override
  List<AvailableLoad> get allAvailableLoads => [_sampleLoad];

  @override
  List<ActiveTrip> get activeTrips => [_trip];

  @override
  List<TruckModel> get myTrucks => [
        TruckModel(
          truckId: 'trk-1',
          ownerId: 'driver-999',
          truckType: 'Tata 14T',
          registrationNumber: 'UP 32 AB 1234',
          bodyType: 'Closed container',
          homeOrigin: 'Delhi',
          defaultCapacityTons: 14.0,
          status: 'verified',
        ),
      ];

  @override
  Future<String?> acceptLoad(AvailableLoad load) async => null;

  @override
  void dismissInstantAlert({bool declined = false, bool skipOffer = true}) {}

  @override
  Future<void> fetchAll() async {}

  @override
  Future<String?> verifyOtp(ActiveTrip trip, String type, String otp) async => null;

  @override
  Future<String?> advanceTripStatus(
    ActiveTrip trip, {
    Uint8List? photoBytes,
    String? otp,
  }) async => null;

  @override
  void startLocationAwareRecommendations() {}

  @override
  void stopLocationAwareRecommendations() {}

  @override
  void recordLoadView(AvailableLoad load) {}

  @override
  CorridorMatchResult? getMatchResult(String cargoId) => null;

  @override
  void toggleFillMyCapacityMode() {}

  @override
  void setFillMyCapacityMode(bool val) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget _wrap(Widget child, [Size size = const Size(390, 844)]) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>(create: (_) => MockAuthVM()),
      ChangeNotifierProvider<PartnerTripsViewModel>(create: (_) => MockPartnerTripsVM()),
      ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

Future<void> _testResponsive(WidgetTester tester, Widget widget, double w) async {
  tester.view.physicalSize = Size(w * 2, 844 * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  final oldHandler = FlutterError.onError;
  FlutterErrorDetails? caught;
  FlutterError.onError = (details) {
    caught = details;
  };
  await tester.pumpWidget(_wrap(widget, Size(w, 844)));
  await tester.pump();
  FlutterError.onError = oldHandler;

  final err = tester.takeException();
  if (err != null && caught != null) {
    debugPrint('OVERFLOW on ${widget.runtimeType} at ${w}px: ${caught!.exceptionAsString()}');
    if (caught!.informationCollector != null) {
      for (final n in caught!.informationCollector!()) {
        debugPrint(n.toStringDeep());
      }
    }
  }
  expect(err, isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final responsiveWidths = [360.0, 375.0, 390.0, 393.0, 412.0, 428.0];

  group('Partner Flow: Screen 01 - Partner Home Screen', () {
    testWidgets('Renders driver card, earnings, active trip, and bottom nav', (tester) async {
      await tester.pumpWidget(_wrap(const PartnerHomeScreen()));
      await tester.pump();

      expect(find.text('ReDo'), findsOneWidget);
      expect(find.text('Partner'), findsWidgets);
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('₹4,820'), findsOneWidget);
      expect(find.text('Delhi, DL'), findsWidgets);
      expect(find.text('Patna, BR'), findsWidgets);
    });

    for (final w in responsiveWidths) {
      testWidgets('Responsive width ${w}px without layout overflow', (tester) async {
        tester.view.physicalSize = Size(w * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_wrap(const PartnerHomeScreen(), Size(w, 844)));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Partner Flow: Screen 02 - Incoming Trip Request Screen', () {
    testWidgets('Renders 45s offer, route, earnings, Accept/Skip CTAs', (tester) async {
      final load = AvailableLoad(
        cargoId: 'crg_test_offer',
        smeName: 'Apex Electronics',
        origin: 'Delhi, DL',
        destination: 'Patna, BR',
        cargoType: 'Electronics (Mac Mini M4 Pro)',
        weightTons: 12.0,
        offeredPriceInr: 4850.0,
        distanceKm: 1000,
        pickupWindow: 'Pickup in 10 km',
      );

      await tester.pumpWidget(_wrap(IncomingTripRequestScreen(
        load: load,
        secondsRemaining: 42,
        onAccept: () async {},
        onDecline: () {},
      )));
      await tester.pump();

      expect(find.text('New trip request'), findsOneWidget);
      expect(find.text('₹4,850'), findsWidgets);
      expect(find.text('ACCEPT'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
    });

    for (final w in responsiveWidths) {
      testWidgets('Responsive width ${w}px without layout overflow', (tester) async {
        final load = AvailableLoad(
          cargoId: 'crg_test_offer',
          smeName: 'Apex Electronics',
          origin: 'Delhi, DL',
          destination: 'Patna, BR',
          cargoType: 'Electronics',
          weightTons: 12.0,
          offeredPriceInr: 4850.0,
          distanceKm: 1000,
          pickupWindow: 'Pickup in 10 km',
        );

        tester.view.physicalSize = Size(w * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_wrap(IncomingTripRequestScreen(
          load: load,
          secondsRemaining: 42,
          onAccept: () async {},
          onDecline: () {},
        ), Size(w, 844)));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Partner Flow: Screen 03 - Request Details Screen', () {
    final load = AvailableLoad(
      cargoId: 'crg_test_detail',
      smeName: 'Apex Logistics',
      origin: 'Delhi, DL',
      destination: 'Patna, BR',
      cargoType: 'Industrial Machinery',
      weightTons: 14.0,
      offeredPriceInr: 5200.0,
      distanceKm: 1050,
      pickupWindow: 'Pickup 6:00 AM - 9:00 AM',
    );

    testWidgets('Renders cargo, vehicle compatibility, route details', (tester) async {
      await tester.pumpWidget(_wrap(RequestDetailsScreen(
        load: load,
        secondsRemaining: 42,
        onAccept: () async {},
        onDecline: () {},
      )));
      await tester.pump();

      expect(find.text('Trip details'), findsOneWidget);
      expect(find.text('₹5,200', skipOffstage: false), findsWidgets);
      await tester.scrollUntilVisible(find.text('Accept Trip'), 200);
      expect(find.text('Accept Trip'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    for (final w in responsiveWidths) {
      testWidgets('Responsive width ${w}px without layout overflow', (tester) async {
        await _testResponsive(
          tester,
          RequestDetailsScreen(
            load: load,
            secondsRemaining: 42,
            onAccept: () async {},
            onDecline: () {},
          ),
          w,
        );
      });
    }
  });

  group('Partner Flow: Screen 04 - Accepted Trip Screen', () {
    final trip = ActiveTrip(
      bookingId: 'BK-10029',
      cargoId: 'crg_991',
      origin: 'Delhi, DL',
      destination: 'Patna, BR',
      status: 'confirmed',
      payoutInr: 4850.0,
      cargoType: 'Mac Mini M4 Pro (50 units)',
      weightTons: 12.0,
      pickupAddress: 'Okhla Phase 3, Delhi',
      dropAddress: 'Patliputra Industrial Area, Patna',
      shipperName: 'Ritik Kumar',
      shipperPhone: '+91 98765 43210',
    );

    testWidgets('Renders active trip, shipper info, navigate button', (tester) async {
      await tester.pumpWidget(_wrap(AcceptedTripScreen(trip: trip)));
      await tester.pump();

      expect(find.text('Active trip'), findsOneWidget);
      expect(find.text('Ritik Kumar', skipOffstage: false), findsWidgets);
      await tester.scrollUntilVisible(find.text('Navigate to pickup'), 200);
      expect(find.text('Navigate to pickup'), findsOneWidget);
    });

    for (final w in responsiveWidths) {
      testWidgets('Responsive width ${w}px without layout overflow', (tester) async {
        await _testResponsive(tester, AcceptedTripScreen(trip: trip), w);
      });
    }
  });

  group('Partner Flow: Screen 05 - Navigation Screen', () {
    final trip = ActiveTrip(
      bookingId: 'BK-10029',
      cargoId: 'crg_991',
      origin: 'Delhi, DL',
      destination: 'Patna, BR',
      status: 'in_transit',
      payoutInr: 4850.0,
      cargoType: 'Electronics',
      weightTons: 12.0,
      pickupAddress: 'Okhla Phase 3, Delhi',
      dropAddress: 'Patliputra Industrial Area, Patna',
      shipperName: 'Ritik Kumar',
      shipperPhone: '+91 98765 43210',
    );

    testWidgets('Renders 3D navigation panel, guidance banner, arrived button', (tester) async {
      await tester.pumpWidget(_wrap(NavigationScreen(trip: trip)));
      await tester.pump();

      expect(find.text('On the way to pickup'), findsOneWidget);
      expect(find.text('Arrived at pickup'), findsOneWidget);
    });

    for (final w in responsiveWidths) {
      testWidgets('Responsive width ${w}px without layout overflow', (tester) async {
        await _testResponsive(tester, NavigationScreen(trip: trip), w);
      });
    }
  });

  group('Partner Flow: Screen 06 - Pickup Verification Screen', () {
    final trip = ActiveTrip(
      bookingId: 'BK-10029',
      cargoId: 'crg_991',
      origin: 'Delhi, DL',
      destination: 'Patna, BR',
      status: 'pickup_ready',
      payoutInr: 4850.0,
      cargoType: 'Mac Mini M4 Pro (50 units)',
      weightTons: 12.0,
      pickupAddress: 'Okhla Phase 3, Delhi',
      dropAddress: 'Patliputra Industrial Area, Patna',
      shipperName: 'Ritik Kumar',
      shipperPhone: '+91 98765 43210',
    );

    testWidgets('Renders arrived at pickup, OTP inputs, Confirm pickup CTA', (tester) async {
      await tester.pumpWidget(_wrap(PickupVerificationScreen(trip: trip)));
      await tester.pump();

      expect(find.text('ReDo'), findsOneWidget);
      expect(find.text('Arrived at pickup'), findsOneWidget);
      expect(find.text('Confirm pickup'), findsWidgets);
    });

    for (final w in responsiveWidths) {
      testWidgets('Responsive width ${w}px without layout overflow', (tester) async {
        await _testResponsive(tester, PickupVerificationScreen(trip: trip), w);
      });
    }
  });

  group('Partner Flow: Screen 07 - Active Delivery Screen', () {
    final trip = ActiveTrip(
      bookingId: 'BK-10029',
      cargoId: 'crg_991',
      origin: 'Delhi, DL',
      destination: 'Patna, BR',
      status: 'in_transit',
      payoutInr: 4850.0,
      cargoType: 'Mac Mini M4 Pro (50 units)',
      weightTons: 12.0,
      pickupAddress: 'Okhla Phase 3, Delhi',
      dropAddress: 'Patliputra Industrial Area, Patna',
      shipperName: 'Ritik Kumar',
      shipperPhone: '+91 98765 43210',
    );

    testWidgets('Renders in-transit progress, ETA, Navigate to delivery CTA', (tester) async {
      await tester.pumpWidget(_wrap(ActiveDeliveryScreen(trip: trip)));
      await tester.pump();

      expect(find.text('ReDo'), findsOneWidget);
      expect(find.text('In transit'), findsWidgets);
      expect(find.text('Navigate to delivery'), findsOneWidget);
    });

    for (final w in responsiveWidths) {
      testWidgets('Responsive width ${w}px without layout overflow', (tester) async {
        await _testResponsive(tester, ActiveDeliveryScreen(trip: trip), w);
      });
    }
  });

  group('Partner Flow: Screen 08 - Delivery OTP Screen', () {
    final trip = ActiveTrip(
      bookingId: 'BK-10029',
      cargoId: 'crg_991',
      origin: 'Delhi, DL',
      destination: 'Patna, BR',
      status: 'in_transit',
      payoutInr: 4850.0,
      cargoType: 'Mac Mini M4 Pro (50 units)',
      weightTons: 12.0,
      pickupAddress: 'Okhla Phase 3, Delhi',
      dropAddress: 'Patliputra Industrial Area, Patna',
      shipperName: 'Ritik Kumar',
      shipperPhone: '+91 98765 43210',
    );

    testWidgets('Renders arrived at destination, delivery OTP inputs, Confirm delivery CTA', (tester) async {
      await tester.pumpWidget(_wrap(DeliveryOtpScreen(trip: trip)));
      await tester.pump();

      expect(find.text('Complete delivery'), findsOneWidget);
      expect(find.text('Arrived at destination'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Confirm delivery'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Confirm delivery'), findsOneWidget);
    });

    for (final w in responsiveWidths) {
      testWidgets('Responsive width ${w}px without layout overflow', (tester) async {
        await _testResponsive(tester, DeliveryOtpScreen(trip: trip), w);
      });
    }
  });

  group('Partner Flow: Screen 09 - Earnings Screen', () {
    testWidgets('Renders monthly earnings hero, metrics, and filter pills', (tester) async {
      await tester.pumpWidget(_wrap(const EarningsScreen()));
      await tester.pump();

      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('This month'), findsWidgets);
    });

    for (final w in responsiveWidths) {
      testWidgets('Earnings screen responsive at ${w}px', (tester) async {
        tester.view.physicalSize = Size(w * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_wrap(const EarningsScreen(), Size(w, 844)));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Partner Flow: Screen 10 - Profile Screen', () {
    testWidgets('Renders verified partner card, vehicle card, sections, and log out', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileScreen()));
      await tester.pump();

      expect(find.text('ReDo'), findsOneWidget);
      expect(find.text('Partner'), findsWidgets);
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('Verified Partner'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Verification'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Support', skipOffstage: false), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Log out'), 200);
      expect(find.text('Log out'), findsOneWidget);
    });

    for (final w in responsiveWidths) {
      testWidgets('Profile screen responsive at ${w}px', (tester) async {
        tester.view.physicalSize = Size(w * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_wrap(const ProfileScreen(), Size(w, 844)));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
