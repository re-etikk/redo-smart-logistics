import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_partner/core/theme.dart';
import 'package:redo_partner/data/models/models.dart';
import 'package:redo_partner/data/services/voice_assistant_service.dart';
import 'package:redo_partner/main.dart';
import 'package:redo_partner/viewmodels/auth_viewmodel.dart';
import 'package:redo_partner/viewmodels/partner_trips_viewmodel.dart';
import 'package:redo_partner/viewmodels/theme_viewmodel.dart';

class MockAuthViewModel extends ChangeNotifier implements AuthViewModel {
  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  DriverProfile? get profile => DriverProfile(
        id: 'test-driver-id',
        fullName: 'Rajesh Kumar',
        role: 'driver',
        onboardingComplete: true,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockPartnerTripsViewModel extends ChangeNotifier implements PartnerTripsViewModel {
  @override
  List<AvailableLoad> get availableLoads => [];

  @override
  List<ActiveTrip> get activeTrips => [];

  @override
  List<TruckModel> get myTrucks => [
        TruckModel(
          truckId: 'truck-1',
          ownerId: 'test-driver-id',
          truckType: '16T Multi-Axle',
          registrationNumber: 'DL 01 AB 1234',
          bodyType: 'Closed Container',
          homeOrigin: 'Delhi',
          defaultCapacityTons: 16.0,
          status: 'available',
        ),
      ];

  @override
  bool get isLoading => false;

  @override
  String get categoryFilter => 'all';

  @override
  String get searchFilter => '';

  @override
  int get instantSecondsLeft => 0;

  @override
  AvailableLoad? get instantAlertLoad => null;

  @override
  AvailableLoad? get instantLoadAlert => null;

  @override
  int get instantSecondsRemaining => 0;

  @override
  double get totalCapacityTons => 16.0;

  @override
  double get bookedCapacityTons => 9.5;

  @override
  double get availableCapacityTons => 6.5;

  @override
  double get capacityUtilizationPct => 59.0;

  @override
  double get potentialExtraEarningsInr => 15000.0;

  @override
  bool get myCorridorOnly => false;

  @override
  bool get fillMyCapacityMode => false;

  @override
  String get searchFrom => '';

  @override
  String get searchTo => '';

  @override
  String get tonnageFilter => 'all';

  @override
  bool get loadingRecommendations => false;

  @override
  Map<String, dynamic>? get nearbyRecommendations => null;

  @override
  List<Map<String, dynamic>> get recommendedCorridors => const [];

  @override
  List<AvailableLoad> get recommendedLoads => const [];

  @override
  List<AvailableLoad> get allAvailableLoads => const [];

  @override
  Future<void> fetchAll() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockThemeViewModel extends ChangeNotifier implements ThemeViewModel {
  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  Locale get locale => const Locale('en');

  @override
  bool get isDark => false;

  @override
  bool isDarkMode(BuildContext context) => false;

  @override
  bool get isMetric => true;

  @override
  String get selectedUnits => 'Metric (Kg, Km)';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockVoiceAssistantService extends ChangeNotifier implements VoiceAssistantService {
  @override
  VoiceAssistantState get state => VoiceAssistantState.idle;

  @override
  String get transcribedText => '';

  @override
  String get currentText => '';

  @override
  String get lastResponse => '';

  @override
  VoiceAssistantAction? get lastAction => null;

  @override
  bool get isListening => false;

  @override
  bool get isProcessing => false;

  @override
  bool get isAvailable => false;

  @override
  bool get continuousMode => false;

  @override
  String get activeAiEngine => 'Sarvam AI 105B';

  @override
  List<ChatMessage> get chatHistory => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('PartnerMainTabs renders and switches tabs smoothly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>(
            create: (_) => MockAuthViewModel(),
          ),
          ChangeNotifierProvider<PartnerTripsViewModel>(
            create: (_) => MockPartnerTripsViewModel(),
          ),
          ChangeNotifierProvider<ThemeViewModel>(
            create: (_) => MockThemeViewModel(),
          ),
          ChangeNotifierProvider<VoiceAssistantService>(
            create: (_) => MockVoiceAssistantService(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PartnerMainTabs(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify bottom navigation items are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Switch to My Trips tab
    await tester.tap(find.text('My Trips'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Switch to Earnings tab
    await tester.tap(find.text('Earnings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Switch to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
