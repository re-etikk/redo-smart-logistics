import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../misc/notifications_screen.dart';
import '../misc/support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final profile = authVM.profile;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Shipper Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.brandYellow,
                      child: Text(
                        (profile?.companyName?.isNotEmpty ?? false) ? profile!.companyName![0].toUpperCase() : 'S',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.slateDark),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.companyName ?? 'Sharma Logistics & Trading',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                          Text(
                            profile?.fullName ?? 'Rajesh Sharma',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              'Verified SME Shipper',
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

            // Settings List
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_city_outlined, color: AppColors.slateDark),
                    title: Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined, color: AppColors.slateDark),
                    title: Text('GST & Billing Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    subtitle: Text('Invoices tab me dekhe - auto 18% GST', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Open the Invoices tab below for GST bills.'))),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.headset_mic_outlined, color: AppColors.slateDark),
                    title: Text('Help & 24x7 Control Desk', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SupportScreen())),
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
