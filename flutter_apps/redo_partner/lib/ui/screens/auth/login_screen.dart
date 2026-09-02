import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../widgets/ui_components.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final success = await authVM.signIn(email, pass);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.errorMessage ?? 'Sign in failed')),
      );
    }
  }

  void _demoLogin() async {
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.demoLogin();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.errorMessage ?? 'Demo sign in failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const RedoPartnerLogo(),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Driver & Partner Sign In',
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Eliminate empty return runs. Maximize monthly earnings with guaranteed advance payouts.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Driver Email or Phone',
                            hintText: 'driver@redo.app',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RedoButton(
                          title: 'Sign In to Driver Console',
                          isLoading: authVM.isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 12),
                        RedoButton(
                          title: '⚡ 1-Tap Quick Demo Driver Login',
                          isSecondary: true,
                          isLoading: authVM.isLoading,
                          onPressed: _demoLogin,
                        ),
                        const SizedBox(height: 12),
                        RedoButton(
                          title: 'Continue with Google',
                          isSecondary: true,
                          isLoading: authVM.isLoading,
                          onPressed: () => authVM.signInWithGoogle(),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupScreen()),
                            ),
                            child: Text(
                              'Register New Truck / Driver Account',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.slateDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
