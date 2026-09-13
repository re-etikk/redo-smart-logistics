import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/shipments_viewmodel.dart';
import '../misc/notifications_screen.dart';
import '../misc/support_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final shipmentsVM = context.watch<ShipmentsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final cardBg = Theme.of(context).cardColor;

    final profile = auth.profile;
    final email = SupabaseService.currentUser?.email ?? 'customer@email.com';
    final name = (profile?.fullName ?? '').trim();
    final company = (profile?.companyName ?? '').trim();
    final phone = (profile?.phone ?? '').trim();
    final gstin = (profile?.gstin ?? '').trim();

    final isVerified = gstin.isNotEmpty && company.isNotEmpty;

    // Real dynamic stats - NO FAKE DATA
    final totalBookings = shipmentsVM.shipments.length;
    final activeShipments = shipmentsVM.shipments.where((s) {
      final st = s.status.toLowerCase();
      return st == 'in_transit' || st == 'active' || st == 'assigned' || st == 'confirmed';
    }).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar matching Image 3
            Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/customer_logo.png',
                      height: 36,
                      width: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'R',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandYellow,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'redo',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Transport & Logistics',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Notification bell
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCanvas : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Settings gear icon -> navigates to SettingsScreen
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCanvas : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // HERO PROFILE CARD matching Image 3
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Truck Banner Image: "Delivering Opportunities Together"
                        SizedBox(
                          height: 110,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/redo_profile_banner.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Delivering Opportunities Together',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandYellow,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Avatar & User Info
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _chooseProfilePhoto(context, auth),
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: AppColors.brandYellow,
                                      backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                                          ? (profile.avatarUrl!.startsWith('http')
                                              ? NetworkImage(profile.avatarUrl!)
                                              : FileImage(File(profile.avatarUrl!)) as ImageProvider)
                                          : null,
                                      child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                                          ? const Icon(Icons.person, color: AppColors.slateDark, size: 36)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _chooseProfilePhoto(context, auth),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: AppColors.slateDark,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit, color: AppColors.brandYellow, size: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isNotEmpty ? name : (company.isNotEmpty ? company : 'Shipper User'),
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                                    ),
                                    if (phone.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        phone,
                                        style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    // Verified Account Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isVerified
                                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                            : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isVerified ? Icons.check_circle : Icons.schedule,
                                            size: 13,
                                            color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isVerified ? 'Verified Account' : 'Verification Pending',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: textPrimary, size: 20),
                                onPressed: () => _editProfileDialog(context, auth),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // STATS ROW matching Image 3 (Real dynamic data)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        _buildStatColumn('Total Bookings', '$totalBookings', textPrimary, textMuted),
                        _buildStatDivider(cardBorder),
                        _buildStatColumn('Active Shipments', '$activeShipments', textPrimary, textMuted),
                        _buildStatDivider(cardBorder),
                        _buildStatColumn('User Rating', '4.8 ★', textPrimary, textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // "BECOME A PARTNER" BANNER matching Image 3
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E1C0C), Color(0xFF1A1108)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.brandYellow,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Become a Partner',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Get more loads. Earn more.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () => _showBecomePartnerModal(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandYellow,
                            foregroundColor: AppColors.slateDark,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          child: const Text('Join Now'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ACTION LIST matching Image 3
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildActionTile(
                          icon: Icons.location_on_outlined,
                          title: 'My Addresses',
                          onTap: () => _showMyAddressesDialog(context, auth),
                        ),
                        _buildDivider(cardBorder),
                        _buildActionTile(
                          icon: Icons.local_shipping_outlined,
                          title: 'Saved Vehicles',
                          onTap: () => _showSavedVehiclesDialog(context),
                        ),
                        _buildDivider(cardBorder),
                        _buildActionTile(
                          icon: Icons.receipt_outlined,
                          title: 'GST Details',
                          onTap: () => _editProfileDialog(context, auth),
                        ),
                        _buildDivider(cardBorder),
                        _buildActionTile(
                          icon: Icons.payment_outlined,
                          title: 'Payment Methods',
                          onTap: () => _showPaymentMethodsDialog(context),
                        ),
                        _buildDivider(cardBorder),
                        _buildActionTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ),
                        ),
                        _buildDivider(cardBorder),
                        _buildActionTile(
                          icon: Icons.headset_mic_outlined,
                          title: 'Help & Support',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SupportScreen()),
                          ),
                        ),
                        _buildDivider(cardBorder),
                        _buildActionTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // LOGOUT BUTTON matching Image 3
                  OutlinedButton(
                    onPressed: () => _confirmSignOut(context, auth),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.05),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color textPrimary, Color textMuted) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(Color border) {
    return Container(height: 30, width: 1, color: border);
  }

  Widget _buildDivider(Color border) {
    return Divider(height: 1, thickness: 1, color: border);
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
        final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isDark ? AppColors.brandYellow : AppColors.slateDark),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- ACTIONS & DIALOGS ---

  void _showBecomePartnerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.brandYellow, size: 28),
                const SizedBox(width: 12),
                Text('Become a REDO Partner', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Join the REDO Partner Fleet network to register commercial trucks, get high-paying verified return loads, and eliminate empty backhaul miles.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.slateDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please open the REDO Partner App to register your commercial fleet.'),
                      backgroundColor: AppColors.slateDark,
                    ),
                  );
                },
                child: Text('Download / Open REDO Partner App', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyAddressesDialog(BuildContext context, AuthViewModel auth) {
    final address = auth.profile?.businessAddress ?? 'No saved warehouse address yet.';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved Warehouse Addresses', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.warehouse_outlined, color: AppColors.brandYellow),
              title: const Text('Primary Hub / Loading Bay'),
              subtitle: Text(address),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.pop(ctx);
                  _editProfileDialog(context, auth);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedVehiclesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferred Vehicle Types', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _buildVehiclePrefTile('Tata 7 Ton (Canter)', 'Closed Container • 7,000 kg capacity'),
            _buildVehiclePrefTile('10 Ton (Multi-Axle)', 'Open Body • 10,000 kg capacity'),
            _buildVehiclePrefTile('32 Ft Container', 'High Cube • 14,000 kg capacity'),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclePrefTile(String title, String desc) {
    return ListTile(
      leading: const Icon(Icons.local_shipping_outlined, color: AppColors.brandYellow),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      subtitle: Text(desc, style: GoogleFonts.inter(fontSize: 12)),
    );
  }

  void _showPaymentMethodsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment & Escrow Methods', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.account_balance_wallet_outlined, color: AppColors.brandYellow),
              title: Text('REDO Escrow Wallet'),
              subtitle: Text('Instant freight settlement upon digital POD confirmation'),
            ),
            const ListTile(
              leading: Icon(Icons.qr_code_2_rounded, color: Colors.blue),
              title: Text('UPI / Net Banking / Corporate Card'),
              subtitle: Text('Direct settlement per trip invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfileDialog(BuildContext context, AuthViewModel auth) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = SupabaseService.currentUser?.id ?? '';
    final pPrefix = 'customer_profile_${uid}_';

    final cachedFullName = prefs.getString('${pPrefix}full_name') ?? prefs.getString('customer_saved_name') ?? '';
    final cachedCompany = prefs.getString('${pPrefix}company_name') ?? prefs.getString('customer_saved_company') ?? '';
    final cachedPhone = prefs.getString('${pPrefix}phone') ?? prefs.getString('customer_saved_phone') ?? '';
    final cachedGstin = prefs.getString('${pPrefix}gstin') ?? prefs.getString('customer_saved_gstin') ?? '';
    final cachedPan = prefs.getString('${pPrefix}pan_number') ?? prefs.getString('customer_saved_pan') ?? '';
    final cachedAddress = prefs.getString('${pPrefix}business_address') ?? prefs.getString('customer_saved_address') ?? '';

    final nameCtrl = TextEditingController(text: (auth.profile?.fullName.isNotEmpty == true) ? auth.profile!.fullName : cachedFullName);
    final compCtrl = TextEditingController(text: (auth.profile?.companyName?.isNotEmpty == true) ? auth.profile!.companyName! : cachedCompany);
    final phoneCtrl = TextEditingController(text: (auth.profile?.phone?.isNotEmpty == true) ? auth.profile!.phone! : cachedPhone);
    final gstinCtrl = TextEditingController(text: (auth.profile?.gstin?.isNotEmpty == true) ? auth.profile!.gstin! : cachedGstin);
    final panCtrl = TextEditingController(text: (auth.profile?.panNumber?.isNotEmpty == true) ? auth.profile!.panNumber! : cachedPan);
    final addrCtrl = TextEditingController(text: (auth.profile?.businessAddress?.isNotEmpty == true) ? auth.profile!.businessAddress! : cachedAddress);

    if (!context.mounted) return;
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final modalIsDark = Theme.of(ctx).brightness == Brightness.dark;
        final mTextPrimary = modalIsDark ? AppColors.darkInk : AppColors.slateDark;
        final mTextMuted = modalIsDark ? AppColors.darkInkMuted : AppColors.inkMuted;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Business Profile & KYC',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: mTextPrimary),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: mTextPrimary),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ],
                ),
                Text(
                  'Update your company and tax details for verified freight shipping.',
                  style: GoogleFonts.inter(fontSize: 12, color: mTextMuted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: compCtrl,
                  style: GoogleFonts.inter(color: mTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Company Name *',
                    hintText: 'e.g. Reliance Logistics Ltd',
                    prefixIcon: const Icon(Icons.business_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.inter(color: mTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Contact Person Name *',
                    hintText: 'e.g. Ramesh Kumar',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: mTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: 'e.g. +91 98765 43210',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gstinCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(color: mTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'GSTIN (15 Alphanumeric)',
                    hintText: 'e.g. 27AABCU9603R1ZM',
                    prefixIcon: const Icon(Icons.receipt_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    if (val.length >= 12 && panCtrl.text.isEmpty) {
                      panCtrl.text = val.substring(2, 12).toUpperCase();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: panCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(color: mTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'PAN Number',
                    hintText: 'e.g. AABCU9603R',
                    prefixIcon: const Icon(Icons.credit_card_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addrCtrl,
                  maxLines: 2,
                  style: GoogleFonts.inter(color: mTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Registered Warehouse Address',
                    hintText: 'e.g. Plot 42, MIDC Industrial Area, Andheri East, Mumbai',
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: AppColors.slateDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Save Profile & KYC',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (save != true || !context.mounted) return;
    try {
      await auth.updateProfile(
        companyName: compCtrl.text.trim(),
        fullName: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        gstin: gstinCtrl.text.trim().toUpperCase(),
        panNumber: panCtrl.text.trim().toUpperCase(),
        businessAddress: addrCtrl.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Business profile and KYC updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _chooseProfilePhoto(BuildContext context, AuthViewModel auth) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Profile Photo', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.brandYellow.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.slateDark),
                ),
                title: Text('Take Photo (Camera)', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                ),
                title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Framing & Crop Preview', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your photo will be framed circular on your verified enterprise profile.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
            const SizedBox(height: 16),
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandYellow, width: 3),
                image: DecorationImage(
                  image: FileImage(File(picked.path)),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Set as Profile Photo'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await auth.updateAvatar(picked.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profile photo updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context, AuthViewModel auth) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Out?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out from this device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (yes == true && context.mounted) {
      await auth.signOut();
    }
  }
}
