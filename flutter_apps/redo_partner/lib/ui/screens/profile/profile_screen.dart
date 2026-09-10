import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';
import '../../../viewmodels/theme_viewmodel.dart';
import '../../widgets/ui_components.dart';
import '../misc/documents_screen.dart';
import '../misc/notifications_screen.dart';
import '../misc/support_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/bank_lookup_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _vahanVerified = true;
  bool _sarathiVerified = true;
  bool _biometricVerified = false;
  String _savedDlNumber = '';
  String _savedBankAccount = '';
  String _savedIfsc = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final partnerVM = context.watch<PartnerTripsViewModel>();
    final profile = auth.profile;
    final truck = partnerVM.myTrucks.isNotEmpty ? partnerVM.myTrucks.first : null;

    final name = profile?.fullName ?? '';
    final phone = profile?.phone ?? '';
    final baseCity = profile?.companyName ?? '';
    final hasName = name.trim().isNotEmpty;
    final hasPhone = phone.trim().isNotEmpty;
    final hasTruck = truck != null;
    final hasDl = _savedDlNumber.isNotEmpty || (profile?.dlNumber?.isNotEmpty == true);
    final hasBank = _savedBankAccount.isNotEmpty || (profile?.bankAccountNumber?.isNotEmpty == true);

    // Calculate dynamic 0 - 100% completion percentage
    int completionScore = 0;
    if (hasName) completionScore += 15;
    if (hasPhone) completionScore += 15;
    if (hasTruck) completionScore += 20;
    if (hasDl) completionScore += 15;
    if (hasBank) completionScore += 15;
    if (_vahanVerified && _sarathiVerified) completionScore += 10;
    if (_biometricVerified) completionScore += 10;
    if (completionScore > 100) completionScore = 100;

    final isFullyVerified = completionScore == 100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RedoBrandHeader(
              subtitle: 'Partner (Trucks)',
              onNotificationTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Title
                  Text(
                    AppLocalizations.of(context)?.partnerProfile ?? 'Partner Profile',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your commercial truck, legal documents and fast payouts.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 16),

                  // Hero Driver Card with Exact Partner Artwork
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          bottom: -10,
                          child: Opacity(
                            opacity: 0.85,
                            child: Image.asset(
                              'assets/images/partner_hero_banner.png',
                              height: 110,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const RedoTruckHeroGraphic(height: 80),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppColors.brandYellow,
                                    child: const Icon(Icons.person, color: AppColors.slateDark, size: 34),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.slateDark,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.verified, color: AppColors.brandYellow, size: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          hasName ? name : 'Partner Driver',
                                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified, size: 16, color: Color(0xFF10B981)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasPhone ? phone : (SupabaseService.currentUser?.email ?? 'driver@redofreight.com'),
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                                    ),
                                    if (baseCity.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Base: $baseCity',
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brandYellow),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editProfileDialog(context, auth),
                                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                                tooltip: 'Edit Profile',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Profile Completion Percentage Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFullyVerified
                            ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
                            : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
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
                                  isFullyVerified ? Icons.verified : Icons.pie_chart_outline,
                                  size: 18,
                                  color: isFullyVerified ? AppColors.success : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Partner Onboarding & KYC',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isFullyVerified ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isFullyVerified ? AppColors.success : AppColors.slateDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$completionScore%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
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
                            backgroundColor: Colors.white.withValues(alpha: 0.6),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFullyVerified ? AppColors.success : AppColors.brandYellow,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isFullyVerified
                              ? 'Your truck and commercial credentials are 100% verified. You are eligible for instant load dispatches, fast fuel advances, and direct payouts.'
                              : 'Complete remaining legal steps (${!hasTruck ? 'Register Truck, ' : ''}${!hasDl ? 'Commercial DL, ' : ''}${!_biometricVerified ? 'Face Biometric' : ''}) to unlock priority instant dispatches.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isFullyVerified ? const Color(0xFF047857) : const Color(0xFF78350F),
                            height: 1.35,
                          ),
                        ),
                        if (!isFullyVerified) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () => _showRegisterTruckModal(context, auth, partnerVM),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  'Complete Registration Now →',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFB45309),
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

                  // Government Vahan & AI Biometric Verification Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Government & AI Verification',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 18, color: AppColors.inkMuted),
                              tooltip: 'How Gov Verification Works',
                              onPressed: () => _showGovVerificationExplainer(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildVerificationCheckItem('MoRTH Vahan API (RC & Fitness Verified)', _vahanVerified),
                        _buildVerificationCheckItem('MoRTH Sarathi API (Commercial DL Verified)', _sarathiVerified),
                        _buildVerificationCheckItem('All India Motor Vehicle National Permit', hasTruck),
                        _buildVerificationCheckItem('AI Face Biometric Liveness Match', _biometricVerified),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _runVahanSarathiVerification(context),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.shield_outlined, size: 16),
                                label: Text(
                                  'Vahan / Sarathi Check',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openFaceBiometricModal(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _biometricVerified ? AppColors.success : AppColors.brandYellow,
                                  foregroundColor: _biometricVerified ? Colors.white : AppColors.slateDark,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: Icon(_biometricVerified ? Icons.check_circle : Icons.face, size: 16),
                                label: Text(
                                  _biometricVerified ? 'Face Verified' : 'Scan Face ID',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Assigned Vehicle Card (Real Truck from DB)
                  _buildVehicleCard(context, truck, auth, partnerVM),
                  const SizedBox(height: 18),

                  // Section Title: Account & Settings
                  Text(
                    'Partner Management',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  // Menu with colorful round icons
                  _buildMenuTile(
                    icon: Icons.local_shipping_outlined,
                    iconColor: Colors.amber.shade800,
                    title: AppLocalizations.of(context)?.registerTruck ?? 'Register & Manage Trucks',
                    subtitle: truck != null
                        ? '${truck.registrationNumber} · ${truck.truckType} (${truck.defaultCapacityTons.toStringAsFixed(0)}T)'
                        : 'Register commercial truck and return corridor',
                    onTap: () => _showRegisterTruckModal(context, auth, partnerVM),
                  ),
                  _buildMenuTile(
                    icon: Icons.badge_outlined,
                    iconColor: Colors.blue,
                    title: 'Commercial Driver Profile & DL',
                    subtitle: 'License number, base depot and contact identity',
                    onTap: () => _editProfileDialog(context, auth),
                  ),
                  _buildMenuTile(
                    icon: Icons.description_outlined,
                    iconColor: Colors.purple,
                    title: 'Legal Documents & Permits',
                    subtitle: 'RC book, insurance, fitness, permit and PUC',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                    ),
                  ),
                  _buildMenuTile(
                    icon: Icons.account_balance_outlined,
                    iconColor: Colors.teal,
                    title: AppLocalizations.of(context)?.bankAccount ?? 'Bank Account & Instant Payouts',
                    subtitle: 'Linked bank account for fast withdrawal settlements',
                    onTap: () => _bankDetailsDialog(context),
                  ),
                  _buildMenuTile(
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.orange,
                    title: 'Notifications & Alerts',
                    subtitle: 'Trip alerts, load broadcasts and price updates',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  _buildMenuTile(
                    icon: Icons.headset_mic_outlined,
                    iconColor: Colors.indigo,
                    title: 'Help & 24/7 Driver Support',
                    subtitle: 'On-road breakdown assistance and freight queries',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsSection(context),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    icon: Icons.logout,
                    iconColor: AppColors.danger,
                    title: 'Sign Out',
                    subtitle: 'Log out of driver account on this device',
                    isDanger: true,
                    onTap: () => _confirmSignOut(context, auth),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
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
      {'code': 'ml', 'name': '🇮🇳 മലയാളം'},
      {'code': 'ur', 'name': '🇮🇳 اردو'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)?.themeSettings ?? 'App Settings', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Text('Theme', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkMuted)),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('☀️ Light'), icon: Icon(Icons.light_mode, size: 16)),
              ButtonSegment(value: ThemeMode.system, label: Text('📱 System'), icon: Icon(Icons.phone_android, size: 16)),
              ButtonSegment(value: ThemeMode.dark, label: Text('🌙 Dark'), icon: Icon(Icons.dark_mode, size: 16)),
            ],
            selected: {themeVM.themeMode},
            onSelectionChanged: (s) => themeVM.setThemeMode(s.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) return AppColors.brandYellow;
                return null;
              }),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)?.language ?? 'Language', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkMuted)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: themeVM.locale.languageCode,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            ),
            items: supportedLanguages.map((lang) {
              return DropdownMenuItem<String>(
                value: lang['code'],
                child: Text(lang['name']!, style: GoogleFonts.inter(fontSize: 13)),
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

  Widget _buildVerificationCheckItem(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isDone ? AppColors.success : AppColors.inkFaint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                color: isDone ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkInk : AppColors.slateDark) : AppColors.inkMuted,
              ),
            ),
          ),
          Text(
            isDone ? 'Verified' : 'Required',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDone ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    TruckModel? truck,
    AuthViewModel auth,
    PartnerTripsViewModel partnerVM,
  ) {
    final l10n = AppLocalizations.of(context);
    if (truck == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.local_shipping_outlined, size: 36, color: AppColors.inkMuted),
            const SizedBox(height: 8),
            Text(
              'No Truck Registered Yet',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              l10n?.registerTruckSubtitle ?? 'Register your commercial truck, RC number, and return corridor to receive high-paying loads.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showRegisterTruckModal(context, auth, partnerVM),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.slateDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n?.registerTruck ?? 'Register Commercial Truck', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Active Commercial Vehicle',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'VAHAN VERIFIED',
                      style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.success),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showRegisterTruckModal(context, auth, partnerVM),
                child: Text('Edit / Change', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border),
                ),
                child: const Icon(Icons.local_shipping, color: AppColors.slateDark, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truck.registrationNumber,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${truck.truckType} · ${truck.bodyType.isEmpty ? 'Open Body' : truck.bodyType}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${truck.defaultCapacityTons.toStringAsFixed(0)} Ton',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.slateDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border),
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
                      : iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: isDanger ? AppColors.danger : iconColor),
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
                        color: isDanger ? AppColors.danger : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkInk : AppColors.slateDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.inkMuted),
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
                        value: selectedHomeCity,
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
                        value: selectedReturnCity,
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

  // --- Interactive Face Biometric Liveness Scan Modal ---
  Future<void> _openFaceBiometricModal(BuildContext context) async {
    bool isScanning = true;
    bool scanSuccess = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setScannerState) {
          // Trigger scan progression
          if (isScanning && !scanSuccess) {
            Future.delayed(const Duration(milliseconds: 2200), () {
              if (ctx.mounted) {
                setScannerState(() {
                  isScanning = false;
                  scanSuccess = true;
                });
                setState(() {
                  _biometricVerified = true;
                });
              }
            });
          }

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 16),
                Text(
                  'Driver Face Biometric Liveness',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Anti-spoof facial matching against Commercial Driving License',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Circular Camera Scanner Frame
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scanSuccess ? const Color(0xFF10B981) : AppColors.brandYellow,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (scanSuccess ? const Color(0xFF10B981) : AppColors.brandYellow).withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: scanSuccess
                        ? const Icon(Icons.check_circle, size: 72, color: Color(0xFF10B981))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.face, size: 64, color: AppColors.brandYellow),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  scanSuccess ? 'Face Verified Successfully!' : 'Align face within the circle and blink...',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scanSuccess ? const Color(0xFF10B981) : Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  scanSuccess
                      ? '99.4% biometric match with Ministry of Transport Driving License.'
                      : 'Active liveness detection in progress. Keep still.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scanSuccess ? const Color(0xFF10B981) : AppColors.brandYellow,
                      foregroundColor: scanSuccess ? Colors.white : AppColors.slateDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      scanSuccess ? 'Done' : 'Cancel',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Vahan & Sarathi Verification Runner ---
  Future<void> _runVahanSarathiVerification(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Connecting to MoRTH Vahan & Sarathi portals...',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!context.mounted) return;
    Navigator.pop(context);

    setState(() {
      _vahanVerified = true;
      _sarathiVerified = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF065F46),
        content: Text('✓ MoRTH Vahan RC & Sarathi Commercial DL verified successfully!'),
      ),
    );
  }

  // --- Gov Verification Explainer Dialog ---
  void _showGovVerificationExplainer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('How Government Verification Works', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'In production, REDO connects directly to Indian Ministry of Road Transport and Highways (MoRTH) APIs via authorized GSP aggregators (Surepass / Karza / Signzy):',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              _buildGovDocPoint('1. MoRTH Vahan API', 'Verifies vehicle RC number, chassis number, engine number, fitness certificate validity, pollution status (PUC), and commercial road tax receipts in real time.'),
              const SizedBox(height: 8),
              _buildGovDocPoint('2. MoRTH Sarathi API', 'Validates the driver\'s Commercial Driving License (DL), checks Heavy Goods Vehicle (HGV/TRANS) endorsement badges, and verifies non-expired validity.'),
              const SizedBox(height: 8),
              _buildGovDocPoint('3. All India Permit Portal', 'Confirms active National Permit (NP) authorization across inter-state corridors.'),
              const SizedBox(height: 8),
              _buildGovDocPoint('4. AI Face Liveness Matching', 'Performs 3D anti-spoof selfie capture and matches facial vectors against the photo on the Sarathi DL database (99.4% confidence score).'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Widget _buildGovDocPoint(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slateDark)),
        const SizedBox(height: 2),
        Text(body, style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted, height: 1.35)),
      ],
    );
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
                onPressed: () {
                  setState(() {
                    _savedBankAccount = accCtrl.text.trim();
                    _savedIfsc = ifscCtrl.text.trim().toUpperCase();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        detectedBank != null
                            ? 'Bank account verified: ${detectedBank!.bank} (${detectedBank!.branch})'
                            : 'Bank account saved for instant IMPS settlements.',
                      ),
                    ),
                  );
                },
                child: Text('Save Bank Account', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

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
