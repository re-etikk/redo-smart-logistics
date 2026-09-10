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
          home: const AuthGate(),
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

  void _handleVoiceAction(VoiceAssistantAction action) {
    switch (action.type) {
      case 'open_bookings':
        setState(() => _currentIndex = 1);
        break;
      case 'track_shipment':
        setState(() => _currentIndex = 2);
        break;
      case 'open_profile':
        setState(() => _currentIndex = 3);
        break;
      default:
        setState(() => _currentIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screens = [
      HomeMapScreen(onTabChangeRequested: (idx) => setState(() => _currentIndex = idx)),
      ShipmentsScreen(onNewBookingPressed: () => setState(() => _currentIndex = 0)),
      const TrackingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: VoiceAssistantFab(onAction: _handleVoiceAction),
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
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: const Icon(Icons.location_on_outlined),
            selectedIcon: const Icon(Icons.location_on, color: AppColors.slateDark),
            label: 'Track',
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
