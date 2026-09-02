import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'data/services/api_service.dart';
import 'core/theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/partner_trips_viewmodel.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/onboarding/partner_onboarding_stepper.dart';
import 'ui/screens/home/available_loads_screen.dart';
import 'ui/screens/trips/active_trip_execution_screen.dart';
import 'ui/screens/earnings/earnings_screen.dart';
import 'ui/screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  ApiService.warmup(); // wake the Render backend early (free tier sleeps)

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
      ],
      child: MaterialApp(
        title: 'REDO Partner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const PartnerAuthGate(),
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

  final List<Widget> _screens = const [
    AvailableLoadsScreen(),
    ActiveTripsScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppColors.brandYellow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore, color: AppColors.slateDark),
            label: 'Find Loads',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: AppColors.slateDark),
            label: 'My Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.slateDark),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.slateDark),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
