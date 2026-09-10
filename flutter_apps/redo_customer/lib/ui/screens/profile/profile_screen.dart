import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/theme_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../invoices/invoices_screen.dart';
import '../misc/notifications_screen.dart';
import '../misc/support_screen.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;

    final profile = auth.profile;
    final email = SupabaseService.currentUser?.email ?? 'customer@email.com';
    final name = profile?.fullName ?? '';
    final company = profile?.companyName ?? '';
    final phone = profile?.phone ?? '';
    final gstin = profile?.gstin ?? '';
    final pan = profile?.panNumber ?? '';
    final address = profile?.businessAddress ?? '';

    final hasPhone = phone.trim().isNotEmpty;
    final hasCompany = company.trim().isNotEmpty;
    final hasName = name.trim().isNotEmpty;
    final hasGstin = gstin.trim().isNotEmpty;
    final hasPan = pan.trim().isNotEmpty || (hasGstin && gstin.length >= 12);
    final hasAddress = address.trim().isNotEmpty;

    // Dynamic profile completion percentage (0 - 100%)
    int completionScore = 0;
    if (email.isNotEmpty) completionScore += 15;
    if (hasCompany) completionScore += 20;
    if (hasName) completionScore += 15;
    if (hasPhone) completionScore += 15;
    if (hasGstin) completionScore += 20;
    if (hasAddress) completionScore += 15;
    if (completionScore > 100) completionScore = 100;

    final isFullyVerified = completionScore == 100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RedoBrandHeader(
              subtitle: 'Transport & Logistics',
              onNotificationTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Title & Subtitle with Localization
                  Text(
                    l10n?.customerProfile ?? 'Customer Profile',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n?.customerProfileSubtitle ?? 'Manage your registered enterprise account and tax compliance.',
                    style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Customer Account Hero Card
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(20),
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
                        // Top Banner Art
                        Container(
                          height: 90,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -10,
                                top: -10,
                                bottom: -10,
                                child: Image.asset(
                                  'assets/images/customer_banner_art.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                top: 18,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandYellow,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l10n?.enterpriseShipper ?? 'ENTERPRISE SHIPPER',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.slateDark,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      hasCompany ? company : (l10n?.registerYourBusiness ?? 'Register Your Business'),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Account Details Row
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _chooseProfilePhoto(context, auth),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppColors.brandYellow,
                                      backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                                          ? (profile.avatarUrl!.startsWith('http')
                                              ? NetworkImage(profile.avatarUrl!)
                                              : FileImage(File(profile.avatarUrl!)) as ImageProvider)
                                          : null,
                                      child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                                          ? const Icon(Icons.person, color: AppColors.slateDark, size: 32)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _chooseProfilePhoto(context, auth),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.slateDark,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.camera_alt, color: AppColors.brandYellow, size: 11),
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
                                      hasName ? name : (hasCompany ? company : 'Shipper User'),
                                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasPhone ? phone : email,
                                      style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                                    ),
                                    if (hasGstin)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'GSTIN: $gstin',
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandYellowDark),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editProfileDialog(context, auth),
                                icon: Icon(Icons.edit_outlined, color: textPrimary),
                                tooltip: l10n?.edit ?? 'Edit profile',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Profile Completion % Card (Adaptive Dark & Light)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? (isFullyVerified
                                ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                                : [const Color(0xFF3B2506), const Color(0xFF1F1403)])
                            : (isFullyVerified
                                ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
                                : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isFullyVerified ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isFullyVerified ? Icons.verified_user : Icons.pie_chart_outline,
                                  size: 18,
                                  color: isFullyVerified ? AppColors.success : AppColors.brandYellow,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n?.profileCompletion ?? 'Profile Completion',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : (isFullyVerified ? const Color(0xFF065F46) : const Color(0xFF92400E)),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isFullyVerified ? AppColors.success : AppColors.brandYellow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$completionScore%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: isFullyVerified ? Colors.white : AppColors.slateDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: completionScore / 100.0,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFullyVerified ? AppColors.success : AppColors.brandYellow,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isFullyVerified
                              ? (l10n?.profileCompletionVerifiedDesc ?? 'Your business profile and tax credentials are fully verified. You have access to priority driver matching and GST e-invoices.')
                              : (l10n?.profileCompletionPendingDesc ?? 'Complete remaining business details (GSTIN & Address) to reach 100% and unlock instant credit limits and priority corridor matches.'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : (isFullyVerified ? const Color(0xFF047857) : const Color(0xFF78350F)),
                            height: 1.35,
                          ),
                        ),
                        if (!isFullyVerified) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () => _editProfileDialog(context, auth),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  l10n?.completeProfileNow ?? 'Complete Profile Now →',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.brandYellow : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Verification & KYC Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n?.verificationLegalKyc ?? 'Verification & Legal KYC',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFullyVerified
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isFullyVerified ? Icons.check_circle : Icons.pending_outlined,
                                    size: 14,
                                    color: isFullyVerified ? AppColors.success : AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFullyVerified ? (l10n?.fullyVerified ?? 'Fully Verified') : '$completionScore% Done',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isFullyVerified ? AppColors.success : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildKycCheckItem(l10n?.mobileVerification ?? 'Mobile Verification', hasPhone, textPrimary, textMuted),
                        _buildKycCheckItem(l10n?.emailAuthentication ?? 'Email Authentication', email.isNotEmpty, textPrimary, textMuted),
                        _buildKycCheckItem(l10n?.companyRegistration ?? 'Company Registration', hasCompany, textPrimary, textMuted),
                        _buildKycCheckItem(l10n?.gstinTaxCompliance ?? 'GSTIN / Tax Compliance', hasGstin, textPrimary, textMuted),
                        _buildKycCheckItem(l10n?.registeredAddress ?? 'Registered Warehouse Address', hasAddress, textPrimary, textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Business Information Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n?.businessTaxInfo ?? 'Business & Tax Information',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                            TextButton(
                              onPressed: () => _editProfileDialog(context, auth),
                              child: Text(l10n?.edit ?? 'Edit', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandYellowDark)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(l10n?.companyName ?? 'Company Name', hasCompany ? company : (l10n?.notProvided ?? 'Not provided'), textPrimary, textMuted),
                        _buildInfoRow(l10n?.contactPerson ?? 'Contact Person', hasName ? name : (l10n?.notProvided ?? 'Not provided'), textPrimary, textMuted),
                        _buildInfoRow(l10n?.phone ?? 'Phone', hasPhone ? phone : (l10n?.notProvided ?? 'Not provided'), textPrimary, textMuted),
                        _buildInfoRow(l10n?.email ?? 'Email', email, textPrimary, textMuted),
                        _buildInfoRow(l10n?.gstin ?? 'GSTIN', hasGstin ? gstin : (l10n?.pendingRegistration ?? 'Pending registration'), textPrimary, textMuted),
                        if (hasPan) _buildInfoRow(l10n?.panNumber ?? 'PAN Number', pan.isNotEmpty ? pan : gstin.substring(2, 12), textPrimary, textMuted),
                        _buildInfoRow(l10n?.registeredAddress ?? 'Registered Address', hasAddress ? address : (l10n?.notProvided ?? 'Not provided'), textPrimary, textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu Options
                  _buildMenuTile(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    title: l10n?.invoicesBilling ?? 'Invoices & Billing',
                    subtitle: l10n?.invoicesSubtitle ?? 'View GST tax invoices and payment receipts',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvoicesScreen()),
                    ),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.notifications_outlined,
                    title: l10n?.notifications ?? 'Notifications',
                    subtitle: l10n?.notificationsSubtitle ?? 'Shipment alerts, status pings and announcements',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.headset_mic_outlined,
                    title: l10n?.helpSupport ?? 'Help & Support',
                    subtitle: l10n?.helpSupportSubtitle ?? '24/7 dedicated freight and booking assistance',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportScreen()),
                    ),
                  ),
                  _buildSettingsSection(context, l10n, textPrimary, textMuted, cardBorder),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.logout,
                    title: l10n?.logOut ?? 'Log Out',
                    subtitle: l10n?.logOutSubtitle ?? 'Sign out from this device',
                    isDanger: true,
                    onTap: () => _confirmSignOut(context, auth, l10n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycCheckItem(String label, bool isDone, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isDone ? AppColors.success : textMuted,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
              color: isDone ? textPrimary : textMuted,
            ),
          ),
          const Spacer(),
          Text(
            isDone ? 'Verified' : 'Required',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDone ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDanger
                      ? AppColors.danger.withValues(alpha: 0.12)
                      : AppColors.brandYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDanger ? AppColors.danger : (isDark ? AppColors.brandYellow : AppColors.slateDark),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDanger ? AppColors.danger : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfileDialog(BuildContext context, AuthViewModel auth) async {
    final l10n = AppLocalizations.of(context);
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
                      l10n?.editProfileTitle ?? 'Edit Business Profile & KYC',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: mTextPrimary),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: mTextPrimary),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ],
                ),
                Text(
                  l10n?.editProfileSubtitle ?? 'Update your company and tax details for verified freight shipping.',
                  style: GoogleFonts.inter(fontSize: 12, color: mTextMuted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: compCtrl,
                  style: GoogleFonts.inter(color: mTextPrimary),
                  decoration: InputDecoration(
                    labelText: '${l10n?.companyName ?? 'Company Name'} *',
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
                    labelText: '${l10n?.contactPerson ?? 'Contact Person Name'} *',
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
                    labelText: '${l10n?.phone ?? 'Mobile Number'} *',
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
                    labelText: '${l10n?.gstin ?? 'GSTIN'} (15 Alphanumeric)',
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
                    labelText: l10n?.panNumber ?? 'PAN Number',
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
                    labelText: l10n?.registeredAddress ?? 'Registered Warehouse Address',
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
                      l10n?.saveProfileKyc ?? 'Save Profile & KYC',
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
          SnackBar(
            content: Text(l10n?.fullyVerified ?? 'Business profile and KYC updated successfully!'),
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

  Future<void> _confirmSignOut(BuildContext context, AuthViewModel auth, AppLocalizations? l10n) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.logOut ?? 'Log Out?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(l10n?.logOutConfirmMessage ?? 'Are you sure you want to log out from this device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n?.cancel ?? 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.logOut ?? 'Log Out'),
          ),
        ],
      ),
    );

    if (yes == true && context.mounted) {
      await auth.signOut();
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

    // Show circular framing and crop confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Framing & Crop Preview', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your photo will be framed circular on your verified enterprise profile and receipts.',
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
            content: Text('✓ Profile photo updated and saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Widget _buildSettingsSection(BuildContext context, AppLocalizations? l10n, Color textPrimary, Color textMuted, Color cardBorder) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supportedLanguages = [
      {'code': 'en', 'name': '🇮🇳 English'},
      {'code': 'hi', 'name': '🇮🇳 हिंदी'},
      {'code': 'ta', 'name': '🇮🇳 தமிழ்'},
      {'code': 'te', 'name': '🇮🇳 తెలుగు'},
      {'code': 'kn', 'name': '🇮🇳 ಕನ್ನಡ'},
      {'code': 'mr', 'name': '🇮🇳 मराठी'},
      {'code': 'gu', 'name': '🇮🇳 ગુજરાતી'},
      {'code': 'pa', 'name': '🇮🇳 ਪੰਜਾਬੀ'},
      {'code': 'bn', 'name': '🇮🇳 বাংলা'},
      {'code': 'or', 'name': '🇮🇳 ଓଡ଼ିଆ'},
      {'code': 'ml', 'name': '🇮🇳 മലയാളം'},
      {'code': 'ur', 'name': '🇮🇳 اردو'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n?.appSettings ?? 'App Settings', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary)),
          const SizedBox(height: 16),
          Text(l10n?.theme ?? 'Theme', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                _buildThemePill(context, themeVM, ThemeMode.light, 'Light', Icons.light_mode_outlined, isDark),
                _buildThemePill(context, themeVM, ThemeMode.system, 'System', Icons.phone_android_outlined, isDark),
                _buildThemePill(context, themeVM, ThemeMode.dark, 'Dark', Icons.dark_mode_outlined, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n?.language ?? 'Language', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textMuted)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: themeVM.locale.languageCode,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
            ),
            items: supportedLanguages.map((lang) {
              return DropdownMenuItem<String>(
                value: lang['code'],
                child: Text(lang['name']!, style: GoogleFonts.inter(fontSize: 13, color: textPrimary)),
              );
            }).toList(),
            onChanged: (code) {
              if (code != null) themeVM.setLocale(Locale(code));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemePill(
    BuildContext context,
    ThemeViewModel themeVM,
    ThemeMode mode,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = themeVM.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => themeVM.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brandYellow.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.slateDark : (isDark ? AppColors.darkInkMuted : AppColors.inkMuted),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? AppColors.slateDark : (isDark ? AppColors.darkInk : AppColors.slateDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
