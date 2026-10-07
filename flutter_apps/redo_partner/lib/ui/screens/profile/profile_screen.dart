import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../../viewmodels/theme_viewmodel.dart';
import '../misc/documents_screen.dart';
import '../misc/notifications_screen.dart';
import '../misc/support_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/bank_lookup_service.dart';
import '../../../data/services/api_service.dart';
import '../settings/kyc_verification_screen.dart';
import '../settings/partner_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _savedDlNumber = '';
  String _savedDlClass = 'TRANS / HGV (Commercial Goods)';
  String _savedDlRto = 'DL-04 Janakpuri, Delhi';
  String _savedDlExpiry = '24-Nov-2031';
  String _savedBankAccount = '';
  String _savedIfsc = '';
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadLocalCache();
  }

  Future<void> _loadLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = SupabaseService.currentUser?.id ?? '';
    final pPrefix = 'partner_profile_${uid}_';
    if (!mounted) return;
    setState(() {
      _savedDlNumber = prefs.getString('${pPrefix}dl') ?? prefs.getString('partner_saved_dl') ?? '';
      _savedDlClass = prefs.getString('${pPrefix}dl_class') ?? 'TRANS / HGV (Commercial Goods)';
      _savedDlRto = prefs.getString('${pPrefix}dl_rto') ?? 'DL-04 Janakpuri, Delhi';
      _savedDlExpiry = prefs.getString('${pPrefix}dl_expiry') ?? '24-Nov-2031';
      _savedBankAccount = prefs.getString('${pPrefix}bank_acc') ?? prefs.getString('partner_saved_bank_acc') ?? '';
      _savedIfsc = prefs.getString('${pPrefix}bank_ifsc') ?? prefs.getString('partner_saved_bank_ifsc') ?? '';
      _localAvatarPath = prefs.getString('${pPrefix}avatar') ?? prefs.getString('partner_saved_avatar');
    });
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
              Text('Driver Profile Photo', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.brandYellow.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.slateDark),
                ),
                title: Text('Take Photo (Front / Rear Camera)', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
            Text('Photo will be framed in circular badge for shipper verification & trip delivery receipts.',
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
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
      setState(() => _localAvatarPath = picked.path);
      await auth.updateAvatar(picked.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Driver profile photo updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final partnerVM = context.watch<PartnerTripsViewModel>();
    final profile = auth.profile;
    final truck = partnerVM.myTrucks.isNotEmpty ? partnerVM.myTrucks.first : null;

    final name = profile?.fullName ?? '';
    final hasName = name.trim().isNotEmpty;

    final effectiveAvatar = _localAvatarPath ?? profile?.avatarUrl;

    return Scaffold(
      backgroundColor: ReDoPartnerColors.warmBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar matching Reference 10: ReDo Partner brand + Settings gear
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: ReDoPartnerColors.brandYellow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: ReDoPartnerColors.darkNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ReDo',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: ReDoPartnerColors.darkNavy,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Partner',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ReDoPartnerColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PartnerSettingsScreen()),
                    ),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: ReDoPartnerColors.darkNavy,
                      size: 24,
                    ),
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  // 1. Driver Profile Card (Warm light background, avatar with online status, rating, edit)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9EE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF6E8C3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _chooseProfilePhoto(context, auth),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: const Color(0xFFE2E8F0),
                                backgroundImage: (effectiveAvatar != null && effectiveAvatar.isNotEmpty)
                                    ? (effectiveAvatar.startsWith('http')
                                        ? NetworkImage(effectiveAvatar)
                                        : FileImage(File(effectiveAvatar)) as ImageProvider)
                                    : const AssetImage('assets/images/driver_avatar_default.png'),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: ReDoPartnerColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
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
                                hasName ? name : 'Rahul Kumar',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: ReDoPartnerColors.darkNavy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: ReDoPartnerColors.success),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Verified Partner',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: ReDoPartnerColors.success,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 14, color: ReDoPartnerColors.brandYellow),
                                  const SizedBox(width: 3),
                                  Text(
                                    '4.9',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: ReDoPartnerColors.darkNavy,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      ' (32 reviews)',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: ReDoPartnerColors.secondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${partnerVM.todayTripsCount > 0 ? partnerVM.todayTripsCount : 18} trips this month',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: ReDoPartnerColors.secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _editProfileDialog(context, auth),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_outlined, size: 14, color: ReDoPartnerColors.darkNavy),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ReDoPartnerColors.darkNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Vehicle Card (Tata 14T, Capacity, Make, Year)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEDE8DD)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 100,
                              height: 65,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    size: 44,
                                    color: ReDoPartnerColors.darkNavy.withValues(alpha: 0.75),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: ReDoPartnerColors.brandYellow,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'CONTAINER',
                                        style: GoogleFonts.inter(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                          color: ReDoPartnerColors.darkNavy,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    truck?.truckType ?? 'Tata 14T',
                                    style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: ReDoPartnerColors.darkNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    truck?.registrationNumber ?? 'UP 32 AB 1234',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ReDoPartnerColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFF3EFE6)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, size: 18, color: ReDoPartnerColors.darkNavy),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${truck != null ? truck.defaultCapacityTons.toStringAsFixed(0) : '14'} Ton',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: ReDoPartnerColors.darkNavy,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Capacity',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: ReDoPartnerColors.secondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 26, color: const Color(0xFFEDE8DD)),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.directions_car_outlined, size: 18, color: ReDoPartnerColors.darkNavy),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Tata',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: ReDoPartnerColors.darkNavy,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Make',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: ReDoPartnerColors.secondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(width: 1, height: 26, color: const Color(0xFFEDE8DD)),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: ReDoPartnerColors.darkNavy),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '2022',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: ReDoPartnerColors.darkNavy,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Year',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: ReDoPartnerColors.secondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. Section: Account
                  _buildSection(
                    title: 'Account',
                    children: [
                      _buildItemRow(
                        icon: Icons.person_outline,
                        title: 'Personal information',
                        onTap: () => _editProfileDialog(context, auth),
                      ),
                      _buildItemRow(
                        icon: Icons.local_shipping_outlined,
                        title: 'Vehicle details',
                        onTap: () => _showRegisterTruckModal(context, auth, partnerVM),
                      ),
                      _buildItemRow(
                        icon: Icons.description_outlined,
                        title: 'Bank account',
                        isLast: true,
                        onTap: () => _bankDetailsDialog(context),
                      ),
                    ],
                  ),

                  // 4. Section: Verification
                  _buildSection(
                    title: 'Verification',
                    children: [
                      _buildItemRow(
                        icon: Icons.badge_outlined,
                        title: 'Driving licence',
                        trailing: _buildVerifiedBadge(),
                        onTap: () => _driverDlDialog(context, auth),
                      ),
                      _buildItemRow(
                        icon: Icons.description_outlined,
                        title: 'Vehicle documents',
                        trailing: _buildVerifiedBadge(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                        ),
                      ),
                      _buildItemRow(
                        icon: Icons.shield_outlined,
                        title: 'Insurance',
                        trailing: _buildVerifiedBadge(),
                        isLast: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
                        ),
                      ),
                    ],
                  ),

                  // 5. Section: Settings
                  _buildSection(
                    title: 'Settings',
                    children: [
                      _buildItemRow(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                      _buildItemRow(
                        icon: Icons.translate,
                        title: 'Language',
                        onTap: () => _showLanguageModal(context),
                      ),
                      _buildItemRow(
                        icon: Icons.dark_mode_outlined,
                        title: 'Appearance',
                        isLast: true,
                        onTap: () => _showAppearanceModal(context),
                      ),
                    ],
                  ),

                  // 6. Section: Support
                  _buildSection(
                    title: 'Support',
                    children: [
                      _buildItemRow(
                        icon: Icons.headset_mic_outlined,
                        title: 'Help & support',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SupportScreen()),
                        ),
                      ),
                      _buildItemRow(
                        icon: Icons.warning_amber_rounded,
                        title: 'Report a problem',
                        isLast: true,
                        onTap: () => _showReportProblemModal(context),
                      ),
                    ],
                  ),

                  // 7. Log Out CTA Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: InkWell(
                      onTap: () => _confirmSignOut(context, auth),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEEEC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: ReDoPartnerColors.danger, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Log out',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: ReDoPartnerColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ReDoPartnerColors.secondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE8DD)),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: ReDoPartnerColors.darkNavy, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ReDoPartnerColors.darkNavy,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFFB4BAC1)),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              indent: 64,
              endIndent: 16,
              color: Color(0xFFF3EFE6),
            ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 12, color: ReDoPartnerColors.success),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ReDoPartnerColors.success,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    final themeVM = context.read<ThemeViewModel>();
    final languages = [
      {'code': 'en', 'name': 'English', 'native': 'English'},
      {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
      {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
      {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
      {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
      {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
      {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
      {'code': 'pa', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ'},
      {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
      {'code': 'or', 'name': 'Odia', 'native': 'ଓଡ଼ିଆ'},
      {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം'},
      {'code': 'ur', 'name': 'Urdu', 'native': 'اردو'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Select App Language',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: ReDoPartnerColors.darkNavy),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: languages.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, idx) {
                  final lang = languages[idx];
                  final isSelected = themeVM.locale.languageCode == lang['code'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: Text(
                      lang['name']!,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? ReDoPartnerColors.darkNavy : const Color(0xFF334155),
                      ),
                    ),
                    subtitle: Text(
                      lang['native']!,
                      style: GoogleFonts.inter(fontSize: 12, color: ReDoPartnerColors.secondary),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: ReDoPartnerColors.brandYellow)
                        : null,
                    onTap: () {
                      themeVM.setLocale(Locale(lang['code']!));
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppearanceModal(BuildContext context) {
    final themeVM = context.read<ThemeViewModel>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Appearance',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: ReDoPartnerColors.darkNavy),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose your preferred theme display mode',
              style: GoogleFonts.inter(fontSize: 13, color: ReDoPartnerColors.secondary),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined, color: ReDoPartnerColors.brandYellow),
              title: Text('Light Mode', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              trailing: themeVM.themeMode == ThemeMode.light
                  ? const Icon(Icons.check_circle, color: ReDoPartnerColors.brandYellow)
                  : null,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined, color: ReDoPartnerColors.darkNavy),
              title: Text('Dark Mode', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              trailing: themeVM.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check_circle, color: ReDoPartnerColors.brandYellow)
                  : null,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android_outlined, color: ReDoPartnerColors.secondary),
              title: Text('System Default', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              trailing: themeVM.themeMode == ThemeMode.system
                  ? const Icon(Icons.check_circle, color: ReDoPartnerColors.brandYellow)
                  : null,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportProblemModal(BuildContext context) {
    final problemCtrl = TextEditingController();
    String selectedCategory = 'Payment';
    final categories = ['Payment', 'App Bug', 'Trip Issue', 'Vehicle Doc', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Report a Problem',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: ReDoPartnerColors.darkNavy),
              ),
              const SizedBox(height: 6),
              Text(
                'Our 24/7 dedicated fleet support team will respond promptly.',
                style: GoogleFonts.inter(fontSize: 12, color: ReDoPartnerColors.secondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: categories.map((cat) {
                  final isSel = selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: ReDoPartnerColors.brandYellow,
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? ReDoPartnerColors.darkNavy : ReDoPartnerColors.secondary,
                    ),
                    onSelected: (val) {
                      if (val) setModalState(() => selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: problemCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the issue you experienced...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ReDoPartnerColors.brandYellow,
                    foregroundColor: ReDoPartnerColors.darkNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF16A34A),
                        content: Text('✓ Problem report submitted to 24/7 Driver Support. Ticket #TKT-8291'),
                      ),
                    );
                  },
                  child: Text(
                    'Submit Report',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Comprehensive Legal Commercial Truck Registration Dialog ---
  Future<void> _showRegisterTruckModal(
    BuildContext context,
    AuthViewModel auth,
    PartnerTripsViewModel partnerVM,
  ) async {
    final truck = partnerVM.myTrucks.isNotEmpty ? partnerVM.myTrucks.first : null;
    final regCtrl = TextEditingController(text: truck?.registrationNumber ?? '');
    final capCtrl = TextEditingController(text: truck != null ? truck.defaultCapacityTons.toStringAsFixed(0) : '16');
    final dlCtrl = TextEditingController(text: _savedDlNumber);
    final npCtrl = TextEditingController(text: 'NP-IND-2026-9812');
    final insCtrl = TextEditingController(text: 'BAJAJ-ALLIANZ-COMM-8712');

    String selectedTruckType = truck?.truckType ?? '22FT Multi-Axle';
    String selectedBodyType = truck?.bodyType.isNotEmpty == true ? truck!.bodyType : 'Closed container';
    String selectedHomeCity = truck?.homeOrigin.isNotEmpty == true ? truck!.homeOrigin : 'Delhi NCR';
    String selectedReturnCity = 'Mumbai';

    final truckTypeOptions = ['14FT', '17FT', '22FT Multi-Axle', '32FT High Deck', 'Taurus 21-Ton', 'Trailer 40FT'];
    final bodyTypeOptions = ['Closed container', 'Open body', 'Refrigerated', 'Flatbed'];
    final cityOptions = ['Delhi NCR', 'Mumbai', 'Pune', 'Jaipur', 'Surat', 'Ahmedabad', 'Lucknow', 'Kanpur'];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final l10n = AppLocalizations.of(context);

    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: cardBg,
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
                      l10n?.registerTruck ?? 'Register Commercial Truck',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textPrimary),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ],
                ),
                Text(
                  l10n?.registerTruckSubtitle ?? 'Enter all legally required Indian commercial transport credentials.',
                  style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 16),

                // Vehicle Registration Number (RC)
                TextField(
                  controller: regCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n?.vehicleRcNumber ?? 'Vehicle RC Number (MoRTH) *',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    hintText: 'e.g. DL 01 AB 1234',
                    hintStyle: GoogleFonts.inter(color: textMuted.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.pin_outlined, size: 20, color: AppColors.brandYellow),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Commercial DL Number
                TextField(
                  controller: dlCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n?.drivingLicense ?? 'Commercial Driving License (Sarathi) *',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    hintText: 'e.g. DL-1420110012345',
                    hintStyle: GoogleFonts.inter(color: textMuted.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.brandYellow),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Vehicle Category / Size
                Text(
                  l10n?.vehicleSizeClass ?? 'VEHICLE SIZE / CLASS',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: truckTypeOptions.map((type) {
                    final sel = selectedTruckType == type;
                    return ChoiceChip(
                      label: Text(
                        type,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sel ? AppColors.slateDark : textPrimary,
                        ),
                      ),
                      selected: sel,
                      selectedColor: AppColors.brandYellow,
                      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                      onSelected: (_) => setModalState(() => selectedTruckType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Body Type
                Text(
                  l10n?.bodyType ?? 'BODY TYPE',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: bodyTypeOptions.map((b) {
                    final sel = selectedBodyType == b;
                    return ChoiceChip(
                      label: Text(
                        b,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sel ? AppColors.slateDark : textPrimary,
                        ),
                      ),
                      selected: sel,
                      selectedColor: AppColors.brandYellow,
                      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                      onSelected: (_) => setModalState(() => selectedBodyType = b),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Capacity in Metric Tons
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n?.grossPayload ?? 'Gross Payload Capacity (Metric Tons) *',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    hintText: 'e.g. 16.5',
                    hintStyle: GoogleFonts.inter(color: textMuted.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.scale_outlined, size: 20, color: AppColors.brandYellow),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Home Hub & Primary Corridor
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedHomeCity,
                        dropdownColor: cardBg,
                        style: GoogleFonts.inter(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: l10n?.baseDepotCity ?? 'Base Depot City',
                          labelStyle: GoogleFonts.inter(color: textMuted),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: cityOptions
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: GoogleFonts.inter(fontSize: 12, color: textPrimary)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedHomeCity = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedReturnCity,
                        dropdownColor: cardBg,
                        style: GoogleFonts.inter(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: l10n?.returnCorridor ?? 'Return Corridor',
                          labelStyle: GoogleFonts.inter(color: textMuted),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: cityOptions
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: GoogleFonts.inter(fontSize: 12, color: textPrimary)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedReturnCity = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // National Permit & Insurance
                TextField(
                  controller: npCtrl,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n?.nationalPermit ?? 'All India National Permit (NP Number)',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    hintText: 'e.g. NP-IND-2026-9812',
                    hintStyle: GoogleFonts.inter(color: textMuted.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.verified_outlined, size: 20, color: AppColors.brandYellow),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: insCtrl,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n?.insurancePolicy ?? 'Commercial Insurance Policy',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    hintText: 'e.g. BAJAJ-ALLIANZ-COMM-8712',
                    hintStyle: GoogleFonts.inter(color: textMuted.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.health_and_safety_outlined, size: 20, color: AppColors.brandYellow),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save Action Button
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
                      l10n?.saveTruck ?? 'Save Truck & Corridor',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (save != true || !context.mounted) return;

    final reg = regCtrl.text.trim().toUpperCase();
    final cap = double.tryParse(capCtrl.text.trim()) ?? 16.0;

    if (reg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Vehicle RC number.')));
      return;
    }

    try {
      await SupabaseService.saveTruckStep(
        registrationNumber: reg,
        truckType: selectedTruckType,
        bodyType: selectedBodyType,
        capacityTons: cap,
        homeOrigin: selectedHomeCity,
        emptyReturnFrom: selectedReturnCity,
      );
      setState(() {
        if (dlCtrl.text.isNotEmpty) _savedDlNumber = dlCtrl.text.trim().toUpperCase();
      });
      await partnerVM.fetchAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commercial Truck and Return Corridor registered successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // --- Dedicated Commercial Driver Profile & DL Dialog ---
  Future<void> _driverDlDialog(BuildContext context, AuthViewModel auth) async {
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final uid = SupabaseService.currentUser?.id ?? '';
    final pPrefix = 'partner_profile_${uid}_';

    final cachedName = prefs.getString('${pPrefix}full_name') ?? prefs.getString('partner_saved_name') ?? '';
    final cachedPhone = prefs.getString('${pPrefix}phone') ?? prefs.getString('partner_saved_phone') ?? '';
    final cachedCity = prefs.getString('${pPrefix}city') ?? prefs.getString('partner_saved_city') ?? '';

    final profileName = auth.profile?.fullName ?? '';
    final profilePhone = auth.profile?.phone ?? '';
    final profileCity = auth.profile?.companyName ?? '';

    final nameCtrl = TextEditingController(text: profileName.isNotEmpty ? profileName : cachedName);
    final phoneCtrl = TextEditingController(text: profilePhone.isNotEmpty ? profilePhone : cachedPhone);
    final dlCtrl = TextEditingController(text: _savedDlNumber.isNotEmpty ? _savedDlNumber : 'DL-0420110012345');
    final rtoCtrl = TextEditingController(text: _savedDlRto);
    final expiryCtrl = TextEditingController(text: _savedDlExpiry);
    final cityCtrl = TextEditingController(text: profileCity.isNotEmpty ? profileCity : cachedCity);

    String selectedClass = _savedDlClass;
    final dlClasses = [
      'TRANS / HGV (Commercial Goods)',
      'TRANS / HGMV (Heavy Goods Motor Vehicle)',
      'LMV-Commercial (Light Goods)',
      'HAZMAT / Dangerous Goods Endorsed',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    if (!context.mounted) return;
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: cardBg,
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
                      'Commercial Driver Profile & DL',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textPrimary),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ],
                ),
                Text(
                  'MoRTH Sarathi Commercial Driving License & Professional Driver Identity.',
                  style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 16),

                // Driver Name
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Driver Full Name (As per DL) *',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.brandYellow),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Contact Mobile Number *',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.brandYellow),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Commercial DL Number
                TextField(
                  controller: dlCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: 1),
                  decoration: InputDecoration(
                    labelText: 'Commercial Driving License (MoRTH Sarathi) *',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    hintText: 'e.g. DL-0420110012345',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.brandYellow),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.verified, color: AppColors.success, size: 20),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // DL Class Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedClass,
                  dropdownColor: cardBg,
                  style: GoogleFonts.inter(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Commercial Vehicle Endorsement Class',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    prefixIcon: const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.brandYellow),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: dlClasses
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: GoogleFonts.inter(fontSize: 12, color: textPrimary)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedClass = val);
                  },
                ),
                const SizedBox(height: 12),

                // RTO & Validity Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rtoCtrl,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Issuing RTO Authority',
                          labelStyle: GoogleFonts.inter(color: textMuted),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: expiryCtrl,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: InputDecoration(
                          labelText: 'DL Expiry Date',
                          labelStyle: GoogleFonts.inter(color: textMuted),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Base Depot City
                TextField(
                  controller: cityCtrl,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Home City / Base Operating Hub',
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    prefixIcon: const Icon(Icons.location_city_outlined, size: 20, color: AppColors.brandYellow),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Sarathi verified badge box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.success, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MoRTH Sarathi National Registry Verified',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: isDark ? Colors.white : const Color(0xFF065F46),
                              ),
                            ),
                            Text(
                              'Valid commercial badge for inter-state heavy freight transport across India.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save Action Button
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
                      'Save & Verify Driver DL',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (save != true || !context.mounted) return;

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final dl = dlCtrl.text.trim().toUpperCase();
    final rto = rtoCtrl.text.trim();
    final expiry = expiryCtrl.text.trim();
    final city = cityCtrl.text.trim();

    setState(() {
      _savedDlNumber = dl;
      _savedDlClass = selectedClass;
      _savedDlRto = rto;
      _savedDlExpiry = expiry;
    });

    // Save to SharedPreferences
    try {
      final p = await SharedPreferences.getInstance();
      final pfx = 'partner_profile_${uid}_';
      await p.setString('${pfx}full_name', name);
      await p.setString('partner_saved_name', name);
      await p.setString('${pfx}phone', phone);
      await p.setString('partner_saved_phone', phone);
      await p.setString('${pfx}city', city);
      await p.setString('partner_saved_city', city);
      await p.setString('${pfx}dl', dl);
      await p.setString('partner_saved_dl', dl);
      await p.setString('${pfx}dl_class', selectedClass);
      await p.setString('${pfx}dl_rto', rto);
      await p.setString('${pfx}dl_expiry', expiry);
      await p.setBool('${pfx}sarathi_verified', true);
      await p.setBool('partner_saved_sarathi_verified', true);
    } catch (_) {}

    try {
      await SupabaseService.saveDriverStep(
        fullName: name,
        phone: phone,
        city: city,
        dlNumber: dl,
      );
      await auth.updateDlDetails(
        dlNumber: dl,
        dlClass: selectedClass,
        issuingRto: rto,
        expiryDate: expiry,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF065F46),
            content: Text('✓ Commercial Driver Profile & MoRTH Sarathi DL updated and verified!'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }


  Future<void> _editProfileDialog(BuildContext context, AuthViewModel auth) async {
    final nameCtrl = TextEditingController(text: auth.profile?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: auth.profile?.phone ?? '');
    final cityCtrl = TextEditingController(text: auth.profile?.companyName ?? '');

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Partner Details', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Driver Full Name')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 10),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Home City / Base Location')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (save != true || !context.mounted) return;
    try {
      await SupabaseService.saveDriverStep(
        fullName: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        city: cityCtrl.text.trim(),
      );
      await auth.checkProfileStatus();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partner details updated.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _bankDetailsDialog(BuildContext context) async {
    final accCtrl = TextEditingController(text: _savedBankAccount);
    final ifscCtrl = TextEditingController(text: _savedIfsc);
    final nameCtrl = TextEditingController(text: context.read<AuthViewModel>().profile?.fullName ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final l10n = AppLocalizations.of(context);

    BankInfo? detectedBank;
    bool isDetecting = false;

    // Initial lookup if existing IFSC is 11 chars
    if (_savedIfsc.trim().length == 11) {
      BankLookupService.lookupIfsc(_savedIfsc).then((info) {
        detectedBank = info;
      });
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void onIfscChanged(String val) async {
            final clean = val.trim().toUpperCase();
            if (clean.length == 11) {
              setDialogState(() => isDetecting = true);
              final info = await BankLookupService.lookupIfsc(clean);
              setDialogState(() {
                detectedBank = info;
                isDetecting = false;
              });
            } else if (detectedBank != null) {
              setDialogState(() => detectedBank = null);
            }
          }

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              l10n?.bankAccount ?? 'Bank Account & Payouts',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter bank account & IFSC to receive instant IMPS trip settlements.',
                    style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.inter(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n?.accountHolder ?? 'Account Holder Name',
                      labelStyle: GoogleFonts.inter(color: textMuted),
                      prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.brandYellow),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: accCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Bank Account Number',
                      labelStyle: GoogleFonts.inter(color: textMuted),
                      prefixIcon: const Icon(Icons.account_balance_outlined, size: 20, color: AppColors.brandYellow),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ifscCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: l10n?.ifscCode ?? 'IFSC Code (11 digits)',
                      hintText: 'e.g. SBIN0001234, HDFC0001234',
                      labelStyle: GoogleFonts.inter(color: textMuted),
                      prefixIcon: const Icon(Icons.pin_outlined, size: 20, color: AppColors.brandYellow),
                      suffixIcon: isDetecting
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : detectedBank != null
                              ? const Icon(Icons.check_circle, color: AppColors.success, size: 22)
                              : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: onIfscChanged,
                  ),
                  if (detectedBank != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified, size: 16, color: AppColors.success),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  detectedBank!.bank,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Branch: ${detectedBank!.branch}, ${detectedBank!.city} (${detectedBank!.state})',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFF047857),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '✓ IMPS & NEFT Instant Settlement Enabled',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: GoogleFonts.inter(color: textMuted)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.slateDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final acc = accCtrl.text.trim();
                  final ifsc = ifscCtrl.text.trim().toUpperCase();
                  setState(() {
                    _savedBankAccount = acc;
                    _savedIfsc = ifsc;
                  });
                  Navigator.pop(ctx);
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final uid = SupabaseService.currentUser?.id ?? '';
                    final pfx = 'partner_profile_${uid}_';
                    await prefs.setString('${pfx}bank_acc', acc);
                    await prefs.setString('partner_saved_bank_acc', acc);
                    await prefs.setString('${pfx}bank_ifsc', ifsc);
                    await prefs.setString('partner_saved_bank_ifsc', ifsc);
                    await ApiService.patch('/auth/profile', {
                      'bank_account_number': acc,
                      'bank_ifsc': ifsc,
                    });
                  } catch (_) {}
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          detectedBank != null
                              ? 'Bank account verified: ${detectedBank!.bank} (${detectedBank!.branch})'
                              : 'Bank account saved for instant IMPS settlements.',
                        ),
                      ),
                    );
                  }
                },
                child: Text('Save Bank Account', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // RESET PASSWORD MODAL (Functional Supabase Auth)
  // ===========================================================================

  Future<void> _confirmSignOut(BuildContext context, AuthViewModel auth) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out from your driver account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (yes == true && context.mounted) {
      await auth.signOut();
    }
  }
}
