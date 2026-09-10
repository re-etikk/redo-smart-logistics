import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'data/services/api_service.dart';
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
import 'l10n/app_localizations.dart';
import 'ui/widgets/voice_assistant_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  ApiService.warmup();
  runApp(const RedoPartnerApp());
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
          home: const PartnerAuthGate(),
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

class _PartnerMainTabsState extends State<PartnerMainTabs> {
  int _currentIndex = 0;

  void _handleVoiceAction(VoiceAssistantAction action) {
    switch (action.type) {
      case 'check_earnings':
        setState(() => _currentIndex = 2);
        break;
      case 'open_profile':
      case 'register_truck':
        setState(() => _currentIndex = 3);
        break;
      case 'open_trips':
        setState(() => _currentIndex = 1);
        break;
      default:
        setState(() => _currentIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screens = [
      AvailableLoadsScreen(onNavigateToTrips: () => setState(() => _currentIndex = 1)),
      ActiveTripsScreen(onFindLoadsPressed: () => setState(() => _currentIndex = 0)),
      const EarningsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: VoiceAssistantFab(
        onAction: _handleVoiceAction,
      ),
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
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping, color: AppColors.slateDark),
            label: l10n?.myTrips ?? 'My Trips',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet, color: AppColors.slateDark),
            label: l10n?.earnings ?? 'Earnings',
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
