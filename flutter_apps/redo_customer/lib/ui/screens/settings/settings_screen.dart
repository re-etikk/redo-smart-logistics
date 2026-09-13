import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/theme_viewmodel.dart';
import '../misc/notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  String _selectedUnits = 'Metric (Kg, Km)';
  String _defaultLocation = 'Mumbai, Maharashtra';

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('redo_pref_notifications') ?? true;
      _selectedUnits = prefs.getString('redo_pref_units') ?? 'Metric (Kg, Km)';
      _defaultLocation = prefs.getString('redo_pref_default_location') ?? 'Mumbai, Maharashtra';
    });
  }

  Future<void> _savePreference(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is bool) {
      await prefs.setBool(key, val);
    } else if (val is String) {
      await prefs.setString(key, val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final cardBg = Theme.of(context).cardColor;

    final profile = auth.profile;
    final email = SupabaseService.currentUser?.email ?? 'customer@email.com';
    final name = profile?.fullName ?? '';
    final hasCompany = (profile?.companyName ?? '').trim().isNotEmpty;
    final hasGstin = (profile?.gstin ?? '').trim().isNotEmpty;
    final isVerified = hasGstin && hasCompany;

    String initials = 'RC';
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    String currentThemeName = 'System Default';
    if (themeVM.themeMode == ThemeMode.light) currentThemeName = 'Light';
    if (themeVM.themeMode == ThemeMode.dark) currentThemeName = 'Dark';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar matching Image 2
            Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
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
                  // User Avatar with Initials
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.brandYellow,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.slateDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Content Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Page Title
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your app preferences and account settings.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Top Highlight Card: Customise your experience
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.slateDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customise your experience',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Make the app work the way you want.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SECTION 1: Account Settings
                  _buildSectionHeader('Account Settings', textPrimary),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Personal Information',
                          subtitle: name.isNotEmpty ? name : email,
                          onTap: () => _editPersonalInfoDialog(context, auth),
                        ),
                        _buildDivider(cardBorder),
                        _buildSettingTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          onTap: () => _changePasswordDialog(context),
                        ),
                        _buildDivider(cardBorder),
                        _buildSettingTile(
                          icon: Icons.verified_user_outlined,
                          title: 'KYC & Verification',
                          subtitle: isVerified ? 'Verified Enterprise Account' : 'Verification Pending',
                          trailingBadge: Container(
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
                                  size: 12,
                                  color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isVerified ? 'Verified' : 'Pending',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => _showKycDetailsDialog(context, auth),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SECTION 2: App Preferences
                  _buildSectionHeader('App Preferences', textPrimary),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Push alerts and delivery status',
                          trailingWidget: Switch.adaptive(
                            value: _pushNotifications,
                            activeThumbColor: AppColors.brandYellow,
                            activeTrackColor: AppColors.slateDark,
                            onChanged: (val) {
                              setState(() => _pushNotifications = val);
                              _savePreference('redo_pref_notifications', val);
                            },
                          ),
                          onTap: () {
                            setState(() => _pushNotifications = !_pushNotifications);
                            _savePreference('redo_pref_notifications', _pushNotifications);
                          },
                        ),
                        _buildDivider(cardBorder),
                        _buildSettingTile(
                          icon: Icons.language_rounded,
                          title: 'Language',
                          subtitle: _getLanguageDisplayName(themeVM.locale.languageCode),
                          trailingBadge: _buildPillBadge(_getLanguageDisplayName(themeVM.locale.languageCode)),
                          onTap: () => _selectLanguageBottomSheet(context, themeVM),
                        ),
                        _buildDivider(cardBorder),
                        _buildSettingTile(
                          icon: Icons.palette_outlined,
                          title: 'Theme',
                          subtitle: currentThemeName,
                          trailingBadge: _buildPillBadge(currentThemeName),
                          onTap: () => _selectThemeBottomSheet(context, themeVM),
                        ),
                        _buildDivider(cardBorder),
                        _buildSettingTile(
                          icon: Icons.location_on_outlined,
                          title: 'Default Locations',
                          subtitle: _defaultLocation,
                          onTap: () => _editDefaultLocationDialog(context),
                        ),
                        _buildDivider(cardBorder),
                        _buildSettingTile(
                          icon: Icons.straighten_rounded,
                          title: 'Units',
                          subtitle: _selectedUnits,
                          trailingBadge: _buildPillBadge(_selectedUnits),
                          onTap: () => _selectUnitsDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SECTION 3: Privacy & Security
                  _buildSectionHeader('Privacy & Security', textPrimary),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'How we manage and protect your data',
                          onTap: () => _showPrivacyPolicyModal(context),
                        ),
                        _buildDivider(cardBorder),
                        _buildSettingTile(
                          icon: Icons.description_outlined,
                          title: 'Terms & Conditions',
                          subtitle: 'Freight transport service agreements',
                          onTap: () => _showTermsModal(context),
                        ),
                        _buildDivider(cardBorder),
                        _buildSettingTile(
                          icon: Icons.delete_outline_rounded,
                          title: 'Delete Account',
                          subtitle: 'Permanently remove your account and data',
                          isDanger: true,
                          onTap: () => _confirmDeleteAccountDialog(context, auth),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SECTION 4: App Details
                  _buildSectionHeader('App Details', textPrimary),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.inkMuted),
                            const SizedBox(width: 12),
                            Text(
                              'App Version',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'v1.2.0 (Build 42)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION 5: Logout Button matching Image 2
                  OutlinedButton(
                    onPressed: () => _confirmSignOutDialog(context, auth),
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

  Widget _buildSectionHeader(String title, Color textPrimary) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(height: 1, thickness: 1, color: color);
  }

  Widget _buildPillBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.slateDark,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailingBadge,
    Widget? trailingWidget,
    bool isDanger = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDanger
        ? const Color(0xFFEF4444)
        : (isDark ? AppColors.darkInk : AppColors.slateDark);
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDanger
                    ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDanger
                    ? const Color(0xFFEF4444)
                    : (isDark ? AppColors.brandYellow : AppColors.slateDark),
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
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              trailingBadge,
              const SizedBox(width: 6),
            ],
            if (trailingWidget != null)
              trailingWidget
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDanger ? const Color(0xFFEF4444) : textMuted,
              ),
          ],
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'hi':
        return 'हिंदी';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'mr':
        return 'मराठी';
      case 'gu':
        return 'ગુજરાતી';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      case 'bn':
        return 'বাংলা';
      case 'or':
        return 'ଓଡ଼ିଆ';
      case 'ml':
        return 'മലയാളം';
      case 'ur':
        return 'اردو';
      default:
        return 'English';
    }
  }

  // --- DIALOGS & MODALS ---

  Future<void> _editPersonalInfoDialog(BuildContext context, AuthViewModel auth) async {
    final profile = auth.profile;
    final nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    final compCtrl = TextEditingController(text: profile?.companyName ?? '');
    final phoneCtrl = TextEditingController(text: profile?.phone ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final mDark = Theme.of(ctx).brightness == Brightness.dark;
        final mPrimary = mDark ? AppColors.darkInk : AppColors.slateDark;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Personal Information',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: mPrimary)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx, false)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: mPrimary),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: compCtrl,
                style: GoogleFonts.inter(color: mPrimary),
                decoration: const InputDecoration(
                  labelText: 'Company / Business Name',
                  prefixIcon: Icon(Icons.business_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(color: mPrimary),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
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
                  child: Text('Save Details', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true && context.mounted) {
      await auth.updateProfile(
        fullName: nameCtrl.text.trim(),
        companyName: compCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Personal details updated!'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  Future<void> _changePasswordDialog(BuildContext context) async {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Password', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
            ),
            onPressed: () async {
              if (newPassCtrl.text.trim().length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              if (newPassCtrl.text != confirmPassCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              try {
                await SupabaseService.client.auth.updateUser(
                  UserAttributes(password: newPassCtrl.text.trim()),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Password updated successfully!'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _showKycDetailsDialog(BuildContext context, AuthViewModel auth) async {
    final profile = auth.profile;
    final gstin = profile?.gstin ?? '';
    final pan = profile?.panNumber ?? '';
    final address = profile?.businessAddress ?? '';

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KYC & Verification Status',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            _buildKycRow('GSTIN Compliance', gstin.isNotEmpty ? gstin : 'Pending Registration', gstin.isNotEmpty),
            _buildKycRow('PAN Number', pan.isNotEmpty ? pan : (gstin.length >= 12 ? gstin.substring(2, 12) : 'Not Provided'), gstin.isNotEmpty || pan.isNotEmpty),
            _buildKycRow('Registered Warehouse', address.isNotEmpty ? address : 'Not Provided', address.isNotEmpty),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.slateDark,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycRow(String label, String val, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.check_circle : Icons.error_outline, size: 18, color: ok ? AppColors.success : AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
                Text(val, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectLanguageBottomSheet(BuildContext context, ThemeViewModel themeVM) {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'हिंदी (Hindi)'},
      {'code': 'ta', 'name': 'தமிழ் (Tamil)'},
      {'code': 'te', 'name': 'తెలుగు (Telugu)'},
      {'code': 'kn', 'name': 'ಕನ್ನಡ (Kannada)'},
      {'code': 'mr', 'name': 'मराठी (Marathi)'},
      {'code': 'gu', 'name': 'ગુજરાતી (Gujarati)'},
      {'code': 'pa', 'name': 'ਪੰਜਾਬੀ (Punjabi)'},
      {'code': 'bn', 'name': 'বাংলা (Bengali)'},
      {'code': 'or', 'name': 'ଓଡ଼ିଆ (Odia)'},
      {'code': 'ml', 'name': 'മലയാളം (Malayalam)'},
      {'code': 'ur', 'name': 'اردو (Urdu)'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Select App Language',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 12),
          ...languages.map((lang) {
            final isSelected = themeVM.locale.languageCode == lang['code'];
            return ListTile(
              title: Text(lang['name']!, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.brandYellow) : null,
              onTap: () {
                themeVM.setLocale(Locale(lang['code']!));
                Navigator.pop(ctx);
              },
            );
          }),
        ],
      ),
    );
  }

  void _selectThemeBottomSheet(BuildContext context, ThemeViewModel themeVM) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Appearance Theme', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone_android_outlined),
              title: const Text('System Default'),
              trailing: themeVM.themeMode == ThemeMode.system ? const Icon(Icons.check_circle, color: AppColors.brandYellow) : null,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Light'),
              trailing: themeVM.themeMode == ThemeMode.light ? const Icon(Icons.check_circle, color: AppColors.brandYellow) : null,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark'),
              trailing: themeVM.themeMode == ThemeMode.dark ? const Icon(Icons.check_circle, color: AppColors.brandYellow) : null,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editDefaultLocationDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: _defaultLocation);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Default Warehouse Location'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Mumbai, Maharashtra',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brandYellow, foregroundColor: AppColors.slateDark),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && ctrl.text.trim().isNotEmpty) {
      setState(() => _defaultLocation = ctrl.text.trim());
      _savePreference('redo_pref_default_location', _defaultLocation);
    }
  }

  Future<void> _selectUnitsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Measurement Units'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedUnits = 'Metric (Kg, Km)');
              _savePreference('redo_pref_units', _selectedUnits);
              Navigator.pop(ctx);
            },
            child: const Text('Metric (Kg, Km, Tons)'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedUnits = 'Imperial (Lbs, Miles)');
              _savePreference('redo_pref_units', _selectedUnits);
              Navigator.pop(ctx);
            },
            child: const Text('Imperial (Lbs, Miles)'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          children: [
            Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Text(
              'REDO Smart Logistics respects your privacy and is committed to protecting the personally identifiable information and freight data you share with us. We collect route data, GPS tracking, and contact details strictly to coordinate transport operations between verified shippers and fleet owners.\n\nAll data is encrypted in transit and at rest. We never sell your business freight or invoice data to third parties.',
              style: GoogleFonts.inter(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          children: [
            Text('Terms & Conditions', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Text(
              '1. Freight Acceptance: All freight loads booked via REDO are subject to carrier vehicle inspection and weight verification.\n\n2. Real-Time Tracking: Shippers and consignees are granted access to live GPS telemetry during active transit.\n\n3. Payments & Escrow: Booking payments are held securely and released upon digital Proof of Delivery (POD) signature upload.',
              style: GoogleFonts.inter(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccountDialog(BuildContext context, AuthViewModel auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Account?', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFFEF4444))),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and will delete all your booking histories and saved addresses.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await auth.signOut();
    }
  }

  Future<void> _confirmSignOutDialog(BuildContext context, AuthViewModel auth) async {
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
