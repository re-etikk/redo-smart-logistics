import 'package:shared_preferences/shared_preferences.dart';
import 'ui/screens/onboarding/app_onboarding_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'data/services/api_service.dart';
import 'data/services/dispatch_notification_service.dart';
import 'data/services/fcm_service.dart';
import 'data/models/models.dart';
import 'data/services/voice_assistant_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/partner_trips_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/onboarding/partner_onboarding_stepper.dart';
import 'ui/screens/home/available_loads_screen.dart';
import 'ui/screens/trips/active_trip_execution_screen.dart';
import 'ui/screens/earnings/earnings_screen.dart';
import 'ui/screens/profile/profile_screen.dart';
import 'ui/screens/ai/partner_ai_assistant_screen.dart';
import 'l10n/app_localizations.dart';
import 'ui/widgets/voice_assistant_widget.dart';
import 'ui/widgets/instant_load_dispatch_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  ApiService.warmup();
  runApp(const RedoPartnerApp());

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    unawaited(
      FcmService.initialize().catchError((Object error) {
        debugPrint('FCM initialization failed: $error');
      }),
    );
  }
}

class RedoPartnerApp extends StatelessWidget {
  const RedoPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => PartnerTripsViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => VoiceAssistantService()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, _) => MaterialApp(
          title: 'REDO Partner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeVM.themeMode,
          locale: themeVM.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const PartnerAuthGateWithOnboarding(),
        ),
      ),
    );
  }
}

class PartnerAuthGate extends StatelessWidget {
  const PartnerAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    switch (authVM.status) {
      case AuthStatus.loading:
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.brandYellow),
          ),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.onboardingRequired:
        return const PartnerOnboardingStepper();
      case AuthStatus.authenticated:
        return const PartnerMainTabs();
    }
  }
}

class PartnerMainTabs extends StatefulWidget {
  const PartnerMainTabs({super.key});

  @override
  State<PartnerMainTabs> createState() => _PartnerMainTabsState();
}

class _PartnerMainTabsState extends State<PartnerMainTabs>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription<DispatchNotificationAction>? _dispatchActionSubscription;
  StreamSubscription<RemoteMessage>? _fcmMessageSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dispatchActionSubscription = DispatchNotificationService.actions.listen(
      _handleDispatchNotificationAction,
    );
    _fcmMessageSubscription = FcmService.foregroundMessages.listen((message) {
      if (message.data['type'] == 'dispatch_offer') {
        unawaited(
          context.read<PartnerTripsViewModel>().refreshDispatchOffers(),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final action in DispatchNotificationService.takePendingActions()) {
        _handleDispatchNotificationAction(action);
      }
    });
    // Register once: fires for BOTH the mic and the AI text chat sheet, the
    // moment an action is parsed — not after some unrelated future resolves.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VoiceAssistantService>().onActionReady = _handleVoiceAction;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<PartnerTripsViewModel>().setAppInBackground(
      state != AppLifecycleState.resumed,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dispatchActionSubscription?.cancel();
    _fcmMessageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleDispatchNotificationAction(
    DispatchNotificationAction action,
  ) async {
    final tripsVM = context.read<PartnerTripsViewModel>();
    final error = await tripsVM.handleDispatchNotificationAction(
      action.offerId,
      action.action,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else if (action.action == 'dispatch_accept') {
      setState(() => _currentIndex = 1);
    }
  }

  Future<void> _acceptInstantLoad(
    PartnerTripsViewModel tripsVM,
    AvailableLoad load,
  ) async {
    final error = await tripsVM.acceptLoad(load);
    if (error != null) throw Exception(error);
    tripsVM.dismissInstantAlert(skipOffer: false);
    if (mounted) setState(() => _currentIndex = 1);
  }

  void _handleVoiceAction(VoiceAssistantAction action) {
    switch (action.type) {
      case 'search_route':
        final query = [
          action.fromCity,
          action.toCity,
        ].where((c) => c != null && c.trim().isNotEmpty).join(' ');
        if (query.isNotEmpty) {
          context.read<PartnerTripsViewModel>().setSearchFilter(query);
        }
        setState(() => _currentIndex = 0);
        break;
      case 'open_trips':
        setState(() => _currentIndex = 1);
        break;
      case 'check_earnings':
        setState(() => _currentIndex = 2);
        break;
      case 'chat':
      case 'open_ai':
        setState(() => _currentIndex = 3);
        break;
      case 'open_profile':
      case 'register_truck':
        setState(() => _currentIndex = 4);
        break;
      default:
        // 'chat' / 'unknown' — plain conversational answer, no navigation.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screens = [
      AvailableLoadsScreen(
        onNavigateToTrips: () => setState(() => _currentIndex = 1),
      ),
      ActiveTripsScreen(
        onFindLoadsPressed: () => setState(() => _currentIndex = 0),
      ),
      const EarningsScreen(),
      PartnerAiAssistantScreen(
        onTabChangeRequested: (idx) => setState(() => _currentIndex = idx),
      ),
      const ProfileScreen(),
    ];

    return Consumer<PartnerTripsViewModel>(
      builder: (context, tripsVM, _) => Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            body: IndexedStack(index: _currentIndex, children: screens),
            floatingActionButton: _currentIndex == 3
                ? null
                : const VoiceAssistantFab(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _currentIndex = idx),
              indicatorColor: AppColors.brandYellow,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(
                    Icons.home,
                    color: AppColors.slateDark,
                  ),
                  label: l10n?.home ?? 'Home',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.local_shipping_outlined),
                  selectedIcon: const Icon(
                    Icons.local_shipping,
                    color: AppColors.slateDark,
                  ),
                  label: l10n?.myTrips ?? 'My Trips',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.slateDark,
                  ),
                  label: l10n?.earnings ?? 'Earnings',
                ),
                const NavigationDestination(
                  icon: Badge(
                    label: Text(
                      'New',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Color(0xFFEF4444),
                    child: Icon(Icons.auto_awesome_outlined),
                  ),
                  selectedIcon: Badge(
                    label: Text(
                      'New',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Color(0xFFEF4444),
                    child: Icon(Icons.auto_awesome, color: AppColors.slateDark),
                  ),
                  label: 'Fleet AI',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(
                    Icons.person,
                    color: AppColors.slateDark,
                  ),
                  label: l10n?.profile ?? 'Profile',
                ),
              ],
            ),
          ),
          if (tripsVM.instantLoadAlert case final load?)
            Positioned.fill(
              child: InstantLoadDispatchSheet(
                key: ValueKey(load.cargoId),
                load: load,
                secondsRemaining: tripsVM.instantSecondsRemaining,
                onAccept: () => _acceptInstantLoad(tripsVM, load),
                onDecline: tripsVM.declineInstantLoad,
              ),
            ),
        ],
      ),
    );
  }
}

class PartnerAuthGateWithOnboarding extends StatefulWidget {
  const PartnerAuthGateWithOnboarding({super.key});

  @override
  State<PartnerAuthGateWithOnboarding> createState() => _PartnerAuthGateWithOnboardingState();
}

class _PartnerAuthGateWithOnboardingState extends State<PartnerAuthGateWithOnboarding> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool("redo_partner_seen_onboarding_v1") ?? false;
    if (mounted) {
      setState(() => _seenOnboarding = seen);
    }
  }

  Future<void> _markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("redo_partner_seen_onboarding_v1", true);
    if (mounted) {
      setState(() => _seenOnboarding = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    // 1. If already logged in, go straight to main tabs
    if (authVM.status == AuthStatus.authenticated) {
      return const PartnerMainTabs();
    }

    // 2. While checking storage or auth loading, show matching cream screen
    if (_seenOnboarding == null || authVM.status == AuthStatus.loading || authVM.status == AuthStatus.initial) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF8EE),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brandYellow),
        ),
      );
    }

    // 3. First time launch after install -> Show Onboarding
    if (!_seenOnboarding!) {
      return AppOnboardingScreen(
        onFinish: _markComplete,
      );
    }

    // 4. Already completed onboarding -> Go to Login / Auth Gate
    return const PartnerAuthGate();
  }
}
