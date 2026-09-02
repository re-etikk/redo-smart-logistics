import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'data/services/api_service.dart';
import 'core/theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/booking_viewmodel.dart';
import 'viewmodels/shipments_viewmodel.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/onboarding/customer_onboarding_screen.dart';
import 'ui/screens/home/home_map_screen.dart';
import 'ui/screens/shipments/shipments_screen.dart';
import 'ui/screens/invoices/invoices_screen.dart';
import 'ui/screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  ApiService.warmup(); // wake the Render backend early (free tier sleeps)

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
      ],
      child: MaterialApp(
        title: 'REDO Customer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
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
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.brandYellow),
          ),
        );
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

  final List<Widget> _screens = const [
    HomeMapScreen(),
    ShipmentsScreen(),
    InvoicesScreen(),
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
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.slateDark),
            label: 'Book Load',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: AppColors.slateDark),
            label: 'Shipments',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.slateDark),
            label: 'Invoices',
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
