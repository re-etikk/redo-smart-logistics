import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final profile = authVM.profile;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Driver & Fleet Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Driver Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.brandYellow,
                      child: Text(
                        (profile?.fullName.isNotEmpty ?? false) ? profile!.fullName[0].toUpperCase() : 'D',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.slateDark),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.fullName ?? 'Harpreet Singh',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                          Text(
                            profile?.phone ?? '+91 98765 43210',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              'Verified Fleet Partner • 4.9⭐',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Options List
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.local_shipping_outlined, color: AppColors.slateDark),
                    title: Text('My Registered Trucks (DL 01 AB 4321)', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined, color: AppColors.slateDark),
                    title: Text('KYC Documents & Verification', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.language_outlined, color: AppColors.slateDark),
                    title: Text('Language / भाषा (English / हिंदी)', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.headset_mic_outlined, color: AppColors.slateDark),
                    title: Text('Partner 24x7 Helpline', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.danger),
                    title: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.danger)),
                    onTap: () => authVM.signOut(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
