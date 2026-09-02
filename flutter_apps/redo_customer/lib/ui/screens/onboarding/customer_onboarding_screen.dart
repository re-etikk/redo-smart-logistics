import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../widgets/ui_components.dart';

class CustomerOnboardingScreen extends StatefulWidget {
  const CustomerOnboardingScreen({super.key});

  @override
  State<CustomerOnboardingScreen> createState() => _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends State<CustomerOnboardingScreen> {
  final _companyController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _finish() async {
    final company = _companyController.text.trim();
    if (company.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your company or business name')),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    await authVM.completeOnboarding(
      companyName: company,
      fullName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const RedoLogo(),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Setup Business Profile',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Provide your trade/business details for verified GST billing and instant truck dispatch.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _companyController,
                        decoration: const InputDecoration(
                          labelText: 'Company / Business Name *',
                          hintText: 'e.g. Apex Industrial Supplies',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person Name',
                          hintText: 'e.g. Rajesh Sharma',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (for driver dispatch)',
                          hintText: '+91 98765 43210',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      RedoButton(
                        title: 'Save & Go to Booking',
                        isLoading: authVM.isLoading,
                        onPressed: _finish,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
