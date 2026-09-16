import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_strings.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../../viewmodels/theme_viewmodel.dart';
import '../misc/notifications_screen.dart';
import 'kyc_verification_screen.dart';

class PartnerSettingsScreen extends StatefulWidget {
  const PartnerSettingsScreen({super.key});

  @override
  State<PartnerSettingsScreen> createState() => _PartnerSettingsScreenState();
}

class _PartnerSettingsScreenState extends State<PartnerSettingsScreen> {
  bool _loadAlerts = true;
  String _selectedUnits = 'Metric (Kg, Km)';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loadAlerts = prefs.getBool('redo_partner_load_alerts') ?? true;
      _selectedUnits = prefs.getString('redo_pref_units') ?? 'Metric (Kg, Km)';
    });
  }

  Future<void> _savePref(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is bool) await prefs.setBool(key, val);
    if (val is String) await prefs.setString(key, val);
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final partnerVM = context.watch<PartnerTripsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final cardBg = Theme.of(context).cardColor;

    final hasTruck = partnerVM.myTrucks.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
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
                      'assets/images/partner_logo.png',
                      height: 36,
                      width: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'R',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brandYellow),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('redo', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)),
                      Text('Partner Settings', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted)),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCanvas : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_none_rounded, size: 20, color: textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(
                    AppStrings.of(context, 'settings'),
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage commercial truck verification, legal compliance, and language.',
                    style: GoogleFonts.inter(fontSize: 13, color: textMuted),
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Driver & Truck KYC
                  Text('Driver & Truck Verification', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildTile(
                          icon: Icons.verified_user_outlined,
                          title: 'Commercial KYC & Documents',
                          subtitle: hasTruck ? 'Verified Truck Partner' : 'RC, DL & PAN Upload Pending',
                          trailingBadge: _buildBadge(hasTruck ? 'Verified' : 'Pending', hasTruck),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycVerificationScreen())),
                        ),
                        _divider(cardBorder),
                        _buildTile(
                          icon: Icons.local_shipping_outlined,
                          title: 'Vahan & Sarathi Verification',
                          subtitle: 'National transport database verification',
                          trailingBadge: _buildBadge('Active', true),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycVerificationScreen())),
                        ),
                        _divider(cardBorder),
                        _buildTile(
                          icon: Icons.toll_outlined,
                          title: 'FASTag & Toll Clearance',
                          subtitle: 'Automatic toll deductions on highway corridors',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('FASTag is linked to your commercial truck registration.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Preferences
                  Text(AppStrings.of(context, 'appPreferences'), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'Nearby Load Proximity Alerts',
                          subtitle: 'Instant push alerts for loads within 1-5 km',
                          trailingWidget: Switch.adaptive(
                            value: _loadAlerts,
                            activeThumbColor: AppColors.brandYellow,
                            activeTrackColor: AppColors.slateDark,
                            onChanged: (v) {
                              setState(() => _loadAlerts = v);
                              _savePref('redo_partner_load_alerts', v);
                            },
                          ),
                          onTap: () {
                            setState(() => _loadAlerts = !_loadAlerts);
                            _savePref('redo_partner_load_alerts', _loadAlerts);
                          },
                        ),
                        _divider(cardBorder),
                        _buildTile(
                          icon: Icons.language_rounded,
                          title: AppStrings.of(context, 'language'),
                          subtitle: _getLangName(themeVM.locale.languageCode),
                          trailingBadge: _buildPill(_getLangName(themeVM.locale.languageCode)),
                          onTap: () => _selectLanguage(context, themeVM),
                        ),
                        _divider(cardBorder),
                        _buildTile(
                          icon: Icons.palette_outlined,
                          title: AppStrings.of(context, 'theme'),
                          subtitle: themeVM.themeMode == ThemeMode.dark ? 'Dark' : (themeVM.themeMode == ThemeMode.light ? 'Light' : 'System'),
                          trailingBadge: _buildPill(themeVM.themeMode == ThemeMode.dark ? 'Dark' : 'Light'),
                          onTap: () => _selectTheme(context, themeVM),
                        ),
                        _divider(cardBorder),
                        _buildTile(
                          icon: Icons.straighten_rounded,
                          title: AppStrings.of(context, 'units'),
                          subtitle: _selectedUnits,
                          trailingBadge: _buildPill(_selectedUnits),
                          onTap: () => _selectUnits(context, themeVM),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: 24x7 Highway Emergency Support
                  Text('24x7 Highway Support & SOS', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildTile(
                          icon: Icons.support_agent_rounded,
                          title: 'Driver Helpline (Toll-Free)',
                          subtitle: '1800-123-7336 (24x7 Freight Support)',
                          onTap: () => launchUrl(Uri.parse('tel:18001237336')),
                        ),
                        _divider(cardBorder),
                        _buildTile(
                          icon: Icons.emergency_outlined,
                          title: 'National Highway Emergency (NHAI)',
                          subtitle: 'Dial 1033 for crane, ambulance, breakdown',
                          onTap: () => launchUrl(Uri.parse('tel:1033')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 4: Log Out
                  OutlinedButton(
                    onPressed: () async {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Log Out?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                          content: const Text('Are you sure you want to log out of your driver account?'),
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
                        await context.read<AuthViewModel>().signOut();
                      }
                    },
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
                          AppStrings.of(context, 'logOut'),
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444)),
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

  Widget _divider(Color c) => Divider(height: 1, thickness: 1, color: c);

  Widget _buildBadge(String text, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: ok ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slateDark)),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailingBadge,
    Widget? trailingWidget,
  }) {
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
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: isDark ? AppColors.brandYellow : AppColors.slateDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (trailingBadge != null) ...[trailingBadge, const SizedBox(width: 6)],
            if (trailingWidget != null) trailingWidget else Icon(Icons.chevron_right_rounded, size: 20, color: textMuted),
          ],
        ),
      ),
    );
  }

  String _getLangName(String code) {
    switch (code) {
      case 'hi': return 'हिंदी';
      case 'ta': return 'தமிழ்';
      case 'te': return 'తెలుగు';
      case 'kn': return 'ಕನ್ನಡ';
      case 'mr': return 'मराठी';
      case 'gu': return 'ગુજરાતી';
      case 'pa': return 'ਪੰਜਾਬੀ';
      case 'bn': return 'বাংলা';
      case 'or': return 'ଓଡ଼ିଆ';
      case 'ml': return 'മലയാളം';
      case 'ur': return 'اردو';
      default: return 'English';
    }
  }

  void _selectLanguage(BuildContext context, ThemeViewModel themeVM) {
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
            child: Text('Select Partner App Language', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
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

  void _selectTheme(BuildContext context, ThemeViewModel themeVM) {
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

  Future<void> _selectUnits(BuildContext context, ThemeViewModel themeVM) async {
    await showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppStrings.of(context, 'units'), style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        children: [
          SimpleDialogOption(
            onPressed: () {
              const u = 'Metric (Kg, Km)';
              setState(() => _selectedUnits = u);
              _savePref('redo_pref_units', u);
              themeVM.setUnits(u);
              Navigator.pop(ctx);
            },
            child: Text('Metric (Kg, Km, Tons)', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
          SimpleDialogOption(
            onPressed: () {
              const u = 'Imperial (Lbs, Miles)';
              setState(() => _selectedUnits = u);
              _savePref('redo_pref_units', u);
              themeVM.setUnits(u);
              Navigator.pop(ctx);
            },
            child: Text('Imperial (Lbs, Miles)', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
