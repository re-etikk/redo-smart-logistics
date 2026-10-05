import 'package:shared_preferences/shared_preferences.dart';
import 'ui/screens/onboarding/app_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'data/services/api_service.dart';
import 'data/services/voice_assistant_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/booking_viewmodel.dart';
import 'viewmodels/shipments_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/onboarding/customer_onboarding_screen.dart';
import 'ui/screens/home/home_map_screen.dart';
import 'ui/screens/shipments/shipments_screen.dart';
import 'ui/screens/shipments/tracking_screen.dart';
import 'ui/screens/profile/profile_screen.dart';
import 'ui/screens/ai/ai_assistant_screen.dart';
import 'ui/widgets/voice_assistant_widget.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );
  ApiService.warmup();
  runApp(const RedoCustomerApp());
}

class RedoCustomerApp extends StatelessWidget {
  const RedoCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => BookingViewModel()),
        ChangeNotifierProvider(create: (_) => ShipmentsViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => VoiceAssistantService()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, _) => MaterialApp(
          title: 'REDO Customer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeVM.themeMode,
          locale: themeVM.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const CustomerAuthGateWithOnboarding(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    switch (authVM.status) {
      case AuthStatus.loading:
      case AuthStatus.initial:
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.brandYellow)));
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.onboardingRequired:
        return const CustomerOnboardingScreen();
      case AuthStatus.authenticated:
        return const CustomerMainTabs();
    }
  }
}

class CustomerMainTabs extends StatefulWidget {
  const CustomerMainTabs({super.key});

  @override
  State<CustomerMainTabs> createState() => _CustomerMainTabsState();
}

class _CustomerMainTabsState extends State<CustomerMainTabs> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Register once: fires for BOTH the mic and the AI text chat sheet, the
    // moment an action is parsed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VoiceAssistantService>().onActionReady = _handleVoiceAction;
    });
  }

  void _handleVoiceAction(VoiceAssistantAction action) {
    switch (action.type) {
      case 'book_shipment':
        setState(() => _currentIndex = 0);
        break;
      case 'open_bookings':
        setState(() => _currentIndex = 1);
        break;
      case 'track_shipment':
        setState(() => _currentIndex = 2);
        break;
      case 'chat':
      case 'open_ai':
        setState(() => _currentIndex = 3);
        break;
      case 'open_profile':
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
      HomeMapScreen(onTabChangeRequested: (idx) => setState(() => _currentIndex = idx)),
      ShipmentsScreen(onNewBookingPressed: () => setState(() => _currentIndex = 0)),
      TrackingScreen(onTabChangeRequested: (idx) => setState(() => _currentIndex = idx)),
      AiAssistantScreen(onTabChangeRequested: (idx) => setState(() => _currentIndex = idx)),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: _currentIndex == 3 ? null : const VoiceAssistantFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppColors.brandYellow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppColors.slateDark),
            label: l10n?.home ?? 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.article_outlined),
            selectedIcon: const Icon(Icons.article, color: AppColors.slateDark),
            label: l10n?.bookings ?? 'Bookings',
          ),
          NavigationDestination(
            icon: const Icon(Icons.location_on_outlined),
            selectedIcon: const Icon(Icons.location_on, color: AppColors.slateDark),
            label: l10n?.track ?? 'Track',
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome, color: AppColors.slateDark),
            label: 'AI Assistant',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person, color: AppColors.slateDark),
            label: l10n?.profile ?? 'Profile',
          ),
        ],
      ),
    );
  }
}

class CustomerAuthGateWithOnboarding extends StatefulWidget {
  const CustomerAuthGateWithOnboarding({super.key});

  @override
  State<CustomerAuthGateWithOnboarding> createState() => _CustomerAuthGateWithOnboardingState();
}

class _CustomerAuthGateWithOnboardingState extends State<CustomerAuthGateWithOnboarding> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool("redo_customer_seen_onboarding_v1") ?? false;
    if (mounted) {
      setState(() => _seenOnboarding = seen);
    }
  }

  Future<void> _markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("redo_customer_seen_onboarding_v1", true);
    if (mounted) {
      setState(() => _seenOnboarding = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    // 1. If already logged in, go straight to main tabs
    if (authVM.status == AuthStatus.authenticated) {
      return const CustomerMainTabs();
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
    return const AuthGate();
  }
}
