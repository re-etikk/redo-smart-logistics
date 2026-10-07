import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_partner/core/theme.dart';
import 'package:redo_partner/data/models/models.dart';
import 'package:redo_partner/ui/screens/home/partner_home_screen.dart';
import 'package:redo_partner/ui/widgets/redo_partner_components.dart';
import 'package:redo_partner/viewmodels/auth_viewmodel.dart';
import 'package:redo_partner/viewmodels/partner_trips_viewmodel.dart';

class TestAuthVM extends ChangeNotifier implements AuthViewModel {
  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  DriverProfile? get profile => DriverProfile(
        id: 'test-driver-id',
        fullName: 'Rahul Kumar',
        role: 'truck_owner',
        onboardingComplete: true,
        partnerOnboardingComplete: true,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class TestPartnerTripsVM extends ChangeNotifier implements PartnerTripsViewModel {
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
  ActiveTrip? get currentActiveTrip => ActiveTrip(
        bookingId: 'BK-10029',
        cargoId: 'crg_991',
        origin: 'Delhi, DL',
        destination: 'Patna, BR',
        status: 'confirmed',
        payoutInr: 4850.0,
        cargoType: 'Electronics',
        weightTons: 12.0,
        pickupAddress: 'Okhla Phase 3, Delhi',
        dropAddress: 'Patliputra Industrial Area, Patna',
        shipperName: 'Ritik Kumar',
        shipperPhone: '+91 98765 43210',
      );

  @override
  List<AvailableLoad> get availableLoads => [
        AvailableLoad(
          cargoId: 'crg_1',
          smeName: 'Apex Electronics',
          origin: 'Delhi, DL',
          destination: 'Patna, BR',
          cargoType: 'Electronics',
          weightTons: 12.0,
          offeredPriceInr: 4850.0,
          distanceKm: 1000,
          pickupWindow: 'Pickup in 10 km',
        ),
      ];

  @override
  List<ActiveTrip> get activeTrips => [];

  @override
  List<TruckModel> get myTrucks => [
        TruckModel(
          truckId: 'trk-1',
          ownerId: 'test-driver-id',
          truckType: '14 Ton',
          registrationNumber: 'UP 32 AB 1234',
          bodyType: 'Closed',
          homeOrigin: 'Delhi',
          defaultCapacityTons: 14.0,
          status: 'available',
        ),
      ];

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchAll() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const viewports = <String, Size>{
    '360x800': Size(360, 800),
    '375x812': Size(375, 812),
    '390x844': Size(390, 844),
    '393x852': Size(393, 852),
    '412x915': Size(412, 915),
    '428x926': Size(428, 926),
  };

  Widget buildTestWidget({required TestPartnerTripsVM tripsVM}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(create: (_) => TestAuthVM()),
        ChangeNotifierProvider<PartnerTripsViewModel>.value(value: tripsVM),
      ],
      child: MaterialApp(
        theme: ReDoPartnerTheme.lightTheme,
        home: const Scaffold(
          body: PartnerHomeScreen(),
          bottomNavigationBar: PartnerBottomNavigation(
            selectedIndex: 0,
            onItemSelected: _dummySelect,
            unreadMessagesCount: 1,
          ),
        ),
      ),
    );
  }

  for (final entry in viewports.entries) {
    testWidgets('PartnerHomeScreen renders cleanly without overflow on ${entry.key}', (tester) async {
      final tripsVM = TestPartnerTripsVM();
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(tripsVM: tripsVM));
      await tester.pumpAndSettle();

      // Verify no exceptions or overflows occurred
      expect(tester.takeException(), isNull);

      // Verify key elements from Reference 1
      expect(find.text('ReDo'), findsOneWidget);
      expect(find.text('Partner'), findsWidgets);
      expect(find.text("Today's earnings"), findsOneWidget);
      expect(find.text('₹4,820'), findsOneWidget);
      expect(find.text('4 Trips'), findsOneWidget);
      expect(find.text('286 km'), findsOneWidget);
      expect(find.text('4.9 Rating'), findsOneWidget);
      expect(find.text('Current trip'), findsOneWidget);
      expect(find.text('On the way to pickup'), findsOneWidget);
      expect(find.text('Trip opportunities'), findsOneWidget);
      expect(find.text('Quick actions'), findsOneWidget);
      expect(find.text('Trips'), findsWidgets);
      expect(find.text('Earnings'), findsWidgets);
      expect(find.text('Messages'), findsWidgets);
      expect(find.text('Profile'), findsOneWidget);
    });
  }

  testWidgets('Online/Offline toggle updates state interactively', (tester) async {
    final tripsVM = TestPartnerTripsVM();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget(tripsVM: tripsVM));
    await tester.pumpAndSettle();

    expect(find.text('You are ONLINE'), findsOneWidget);
    expect(find.text('Go Offline'), findsOneWidget);

    // Tap "Go Offline"
    await tester.tap(find.text('Go Offline'));
    await tester.pumpAndSettle();

    expect(tripsVM.isOnline, isFalse);
    expect(find.text('You are OFFLINE'), findsOneWidget);
    expect(find.text('Go Online'), findsOneWidget);

    // Tap "Go Online"
    await tester.tap(find.text('Go Online'));
    await tester.pumpAndSettle();

    expect(tripsVM.isOnline, isTrue);
    expect(find.text('You are ONLINE'), findsOneWidget);
    expect(find.text('Go Offline'), findsOneWidget);
  });
}

void _dummySelect(int _) {}
