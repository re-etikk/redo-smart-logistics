import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:redo_customer/data/models/models.dart';
import 'package:redo_customer/ui/screens/profile/profile_screen.dart';
import 'package:redo_customer/viewmodels/auth_viewmodel.dart';
import 'package:redo_customer/viewmodels/theme_viewmodel.dart';

class MockAuthViewModel extends ChangeNotifier implements AuthViewModel {
  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  UserProfile? get profile => UserProfile(
        id: 'test-user-id',
        fullName: 'Ritik Kumar',
        companyName: 'Acme Logistics Ltd',
        role: 'sme',
        phone: '+91 98765 43210',
        onboardingComplete: true,
      );

  @override
  Future<void> updateProfile({
    required String companyName,
    String? fullName,
    String? phone,
    String? gstin,
    String? panNumber,
    String? businessAddress,
    String? avatarUrl,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockThemeViewModel extends ChangeNotifier implements ThemeViewModel {
  ThemeMode _mode = ThemeMode.light;
  Locale _locale = const Locale('en');

  @override
  ThemeMode get themeMode => _mode;

  @override
  Locale get locale => _locale;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
  }

  @override
  Future<void> setLocale(Locale loc) async {
    _locale = loc;
    notifyListeners();
  }

  @override
  String get selectedUnits => 'Metric (Kg, Km)';

  @override
  bool get isMetric => true;

  @override
  bool get isDark => _mode == ThemeMode.dark;

  @override
  bool isDarkMode(BuildContext context) => _mode == ThemeMode.dark;

  @override
  Future<void> setUnits(String units) async {}

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
    testWidgets('Screen 10 — Profile renders with zero overflow on ${vp.width.toInt()}x${vp.height.toInt()}', (tester) async {
      tester.view.physicalSize = vp;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>(create: (_) => MockAuthViewModel()),
            ChangeNotifierProvider<ThemeViewModel>(create: (_) => MockThemeViewModel()),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no exceptions or overflows
      expect(tester.takeException(), isNull);

      // Verify Screen Title & Subtitle
      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('Manage account, business KYC, and preferences.'), findsOneWidget);

      // Verify User Card
      expect(find.text('Ritik Kumar'), findsOneWidget);
      expect(find.text('Acme Logistics Ltd'), findsAtLeastNWidgets(1));
      expect(find.text('Edit profile'), findsOneWidget);

      // Verify Sections
      expect(find.text('Business & KYC'), findsOneWidget);
      expect(find.text('Business Details'), findsOneWidget);
      expect(find.text('Saved Hubs & Addresses'), findsOneWidget);
      expect(find.text('Bank & Payout Details'), findsOneWidget);

      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);

      // Scroll to reveal lower sections in the ListView
      await tester.scrollUntilVisible(find.text('Log out'), 200);

      expect(find.text('Support & Legal'), findsOneWidget);
      expect(find.text('Customer Support'), findsOneWidget);
      expect(find.text('Report a Problem'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
    });
  }

  testWidgets('Screen 10 — "Edit profile" opens bottom sheet and saves changes', (tester) async {
    tester.view.physicalSize = const Size(390.0, 844.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>(create: (_) => MockAuthViewModel()),
          ChangeNotifierProvider<ThemeViewModel>(create: (_) => MockThemeViewModel()),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final editBtn = find.text('Edit profile');
    expect(editBtn, findsOneWidget);
    await tester.tap(editBtn);
    await tester.pumpAndSettle();

    // Verify modal is open
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Company name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);

    // Save changes
    final saveBtn = find.text('Save changes');
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(find.text('Save changes'), findsNothing);
  });

  testWidgets('Screen 10 — Language selection updates active locale', (tester) async {
    tester.view.physicalSize = const Size(390.0, 844.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final themeVM = MockThemeViewModel();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>(create: (_) => MockAuthViewModel()),
          ChangeNotifierProvider<ThemeViewModel>.value(value: themeVM),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final langTile = find.text('Language');
    expect(langTile, findsOneWidget);
    await tester.ensureVisible(langTile);
    await tester.tap(langTile);
    await tester.pumpAndSettle();

    // Modal shows languages
    expect(find.text('Select language'), findsOneWidget);
    final hindiOption = find.text('हिंदी (Hindi)');
    expect(hindiOption, findsOneWidget);
    await tester.tap(hindiOption);
    await tester.pumpAndSettle();

    expect(themeVM.locale.languageCode, equals('hi'));
  });

  testWidgets('Screen 10 — Log out shows confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(390.0, 844.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>(create: (_) => MockAuthViewModel()),
          ChangeNotifierProvider<ThemeViewModel>(create: (_) => MockThemeViewModel()),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final logoutBtn = find.text('Log out');
    await tester.scrollUntilVisible(logoutBtn, 200);
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();

    // Confirm dialog is shown
    expect(find.text('Are you sure you want to log out of ReDo?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
