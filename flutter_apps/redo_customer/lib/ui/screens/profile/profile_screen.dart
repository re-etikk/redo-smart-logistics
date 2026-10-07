import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/places_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/theme_viewmodel.dart';
import '../misc/notifications_screen.dart';
import '../misc/support_screen.dart';
import '../settings/kyc_verification_screen.dart';
import '../wallet/wallet_screen.dart';

/// Screen 10 — ReDo Unified Profile & Settings Hub
/// Consolidates account management, business KYC, bank details with auto-IFSC lookup,
/// Google Places autocomplete saved addresses, appearance/dark mode, and 12 Indian languages.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  String? _bankAccountNumber;
  String? _bankIfsc;
  String? _bankName;
  String? _bankBranch;
  String? _bankCity;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotifications = prefs.getBool('redo_pref_notifications') ?? true;
      _bankAccountNumber = prefs.getString('user_bank_account');
      _bankIfsc = prefs.getString('user_bank_ifsc');
      _bankName = prefs.getString('user_bank_name');
      _bankBranch = prefs.getString('user_bank_branch');
      _bankCity = prefs.getString('user_bank_city');
    });
  }

  Future<void> _saveNotificationPref(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('redo_pref_notifications', val);
    setState(() => _pushNotifications = val);
  }

  // ===========================================================================
  // 1. AVATAR PICKER & PERSISTENCE
  // ===========================================================================
  void _openAvatarOptions(BuildContext context, AuthViewModel auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Profile Photo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3D6),
                child: Icon(Icons.camera_alt_outlined, color: ReDoColors.darkNavy),
              ),
              title: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, auth, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3D6),
                child: Icon(Icons.photo_library_outlined, color: ReDoColors.darkNavy),
              ),
              title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, auth, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3D6),
                child: Icon(Icons.face_retouching_natural_outlined, color: ReDoColors.darkNavy),
              ),
              title: Text('Choose Logistics Avatar Preset', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _choosePresetAvatar(context, auth);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, AuthViewModel auth, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await File(photo.path).readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        await auth.updateAvatar(base64Image);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_saved_avatar_path', base64Image);
        await prefs.setString('customer_saved_avatar', base64Image);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: ReDoColors.primaryYellow,
              content: Text(
                'Profile photo updated permanently.',
                style: GoogleFonts.inter(color: ReDoColors.darkNavy, fontWeight: FontWeight.w700),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update photo: $e')),
        );
      }
    }
  }

  void _choosePresetAvatar(BuildContext context, AuthViewModel auth) {
    final presets = [
      {'name': 'Logistics Director', 'tag': 'preset:director', 'color': 0xFFFFB21A, 'icon': Icons.business_center_rounded},
      {'name': 'Fleet Shipper', 'tag': 'preset:shipper', 'color': 0xFF36A653, 'icon': Icons.local_shipping_rounded},
      {'name': 'Supply Chain Ops', 'tag': 'preset:ops', 'color': 0xFF3B82F6, 'icon': Icons.alt_route_rounded},
      {'name': 'Enterprise Shipper', 'tag': 'preset:enterprise', 'color': 0xFF8B5CF6, 'icon': Icons.domain_rounded},
      {'name': 'Cargo Handler', 'tag': 'preset:cargo', 'color': 0xFFF97316, 'icon': Icons.inventory_2_rounded},
      {'name': 'Logistics Pro', 'tag': 'preset:pro', 'color': 0xFF14B8A6, 'icon': Icons.verified_user_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Logistics Avatar', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: presets.map((p) {
                final color = Color(p['color'] as int);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await auth.updateAvatar(p['tag'] as String);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_saved_avatar_path', p['tag'] as String);
                    await prefs.setString('customer_saved_avatar', p['tag'] as String);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: Icon(p['icon'] as IconData, color: color, size: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(p['name'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(UserProfile? user, double size) {
    final avatar = user?.avatarUrl;

    if (avatar != null && avatar.isNotEmpty) {
      if (avatar.startsWith('preset:')) {
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFFFFECC4),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_pin_circle_rounded, size: size * 0.55, color: ReDoColors.darkNavy),
        );
      }
      if (avatar.startsWith('data:image')) {
        try {
          final comma = avatar.indexOf(',');
          final b64 = comma != -1 ? avatar.substring(comma + 1) : avatar;
          return Image.memory(base64Decode(b64), width: size, height: size, fit: BoxFit.cover);
        } catch (_) {}
      }
      if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
        return Image.network(avatar, width: size, height: size, fit: BoxFit.cover);
      }
      try {
        final f = File(avatar);
        if (f.existsSync()) {
          return Image.file(f, width: size, height: size, fit: BoxFit.cover);
        }
      } catch (_) {}
    }

    return Container(
      width: size,
      height: size,
      color: const Color(0xFFFFDE99),
      alignment: Alignment.center,
      child: Text(
        user?.fullName.isNotEmpty == true ? user!.fullName.substring(0, 1).toUpperCase() : 'R',
        style: GoogleFonts.plusJakartaSans(fontSize: size * 0.45, fontWeight: FontWeight.w900, color: ReDoColors.darkNavy),
      ),
    );
  }

  // ===========================================================================
  // 2. EDIT PROFILE MODAL
  // ===========================================================================
  void _showEditProfileModal(BuildContext context, AuthViewModel auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;

    final nameCtrl = TextEditingController(text: auth.profile?.fullName ?? '');
    final companyCtrl = TextEditingController(text: auth.profile?.companyName ?? '');
    final phoneCtrl = TextEditingController(text: auth.profile?.phone ?? '');
    final gstinCtrl = TextEditingController(text: auth.profile?.gstin ?? '');
    final panCtrl = TextEditingController(text: auth.profile?.panNumber ?? '');
    final addressCtrl = TextEditingController(text: auth.profile?.businessAddress ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
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
                    Expanded(
                      child: Text(
                        'Edit Business Profile',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(labelText: 'Company name', prefixIcon: Icon(Icons.business_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gstinCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'GSTIN (15 characters)', prefixIcon: Icon(Icons.receipt_long_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: panCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'PAN Number (10 characters)', prefixIcon: Icon(Icons.credit_card_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Registered Business Address', prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await auth.updateProfile(
                        fullName: nameCtrl.text.trim(),
                        companyName: companyCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        gstin: gstinCtrl.text.trim(),
                        panNumber: panCtrl.text.trim(),
                        businessAddress: addressCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: ReDoColors.primaryYellow,
                            content: Text('Profile updated successfully.', style: GoogleFonts.inter(color: ReDoColors.darkNavy, fontWeight: FontWeight.w700)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ReDoColors.primaryYellow,
                      foregroundColor: ReDoColors.darkNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save changes', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. SAVED ADDRESSES WITH GOOGLE PLACES AUTOCOMPLETE
  // ===========================================================================
  void _showSavedAddressesModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getAddresses(),
        builder: (context, snapshot) {
          final addresses = snapshot.data ?? [];
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saved Addresses', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 12),
                if (addresses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No saved addresses yet.\nAdd warehouse or hub addresses for 1-tap booking.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText),
                      ),
                    ),
                  )
                else
                  ...addresses.map((a) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, color: ReDoColors.primaryYellow),
                        title: Text('${a['label'] ?? 'Warehouse'}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
                        subtitle: Text('${a['city'] ?? ''}', style: GoogleFonts.inter(color: isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText)),
                      )),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddAddressWithPlacesAutocomplete(context);
                  },
                  icon: const Icon(Icons.add, color: ReDoColors.primaryYellow),
                  label: Text('+ Add New Address (Google Maps)', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddAddressWithPlacesAutocomplete(BuildContext context) {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    List<GooglePlaceSuggestion> suggestions = [];
    Timer? debounce;
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardBg = isDark ? AppColors.darkCard : Colors.white;
          final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;

          void onAddressChanged(String query) {
            debounce?.cancel();
            if (query.trim().length < 2) {
              setModalState(() {
                suggestions = [];
                isSearching = false;
              });
              return;
            }
            setModalState(() => isSearching = true);
            debounce = Timer(const Duration(milliseconds: 350), () async {
              final results = await PlacesService.getAutocompleteSuggestions(query);
              setModalState(() {
                suggestions = results;
                isSearching = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Saved Address', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(labelText: 'Label (e.g. Warehouse 1, Factory, Head Office)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    onChanged: onAddressChanged,
                    decoration: InputDecoration(
                      labelText: 'Search Address or City (Google Places)',
                      prefixIcon: const Icon(Icons.search, color: ReDoColors.primaryYellow),
                      suffixIcon: isSearching ? const SizedBox(width: 16, height: 16, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    ),
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCanvas : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (_, idx) {
                          final p = suggestions[idx];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, color: ReDoColors.primaryYellow, size: 18),
                            title: Text(p.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
                            subtitle: p.secondaryText != null ? Text(p.secondaryText!, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText)) : null,
                            onTap: () {
                              addressCtrl.text = p.description;
                              setModalState(() => suggestions = []);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (addressCtrl.text.trim().isNotEmpty) {
                          await SupabaseService.addAddress(
                            labelCtrl.text.trim().isEmpty ? 'Saved Hub' : labelCtrl.text.trim(),
                            addressCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Address saved.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ReDoColors.primaryYellow,
                        foregroundColor: ReDoColors.darkNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Address', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 4. BANK ACCOUNT DETAILS & AUTO-IFSC LOOKUP
  // ===========================================================================
  void _showBankAccountModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;

    final accountCtrl = TextEditingController(text: _bankAccountNumber ?? '');
    final ifscCtrl = TextEditingController(text: _bankIfsc ?? '');
    String? localBank = _bankName;
    String? localBranch = _bankBranch;
    String? localCity = _bankCity;
    bool isLookingUp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> lookupIfsc(String code) async {
            final trimmed = code.trim().toUpperCase();
            if (trimmed.length != 11) return;
            setModalState(() => isLookingUp = true);
            try {
              final res = await http.get(Uri.parse('https://ifsc.razorpay.com/$trimmed')).timeout(const Duration(seconds: 5));
              if (res.statusCode == 200) {
                final json = jsonDecode(res.body) as Map<String, dynamic>;
                setModalState(() {
                  localBank = json['BANK']?.toString();
                  localBranch = json['BRANCH']?.toString();
                  localCity = json['CITY']?.toString();
                  isLookingUp = false;
                });
              } else {
                setModalState(() => isLookingUp = false);
              }
            } catch (_) {
              setModalState(() => isLookingUp = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
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
                        Expanded(child: Text('Bank Account / Payout', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: accountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Account Number', prefixIcon: Icon(Icons.account_balance)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ifscCtrl,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (v) {
                        if (v.trim().length == 11) {
                          lookupIfsc(v);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'IFSC Code (11 characters)',
                        hintText: 'e.g. SBIN0001234 or HDFC0000001',
                        prefixIcon: const Icon(Icons.pin),
                        suffixIcon: isLookingUp ? const SizedBox(width: 16, height: 16, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                      ),
                    ),
                    if (localBank != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, color: Color(0xFF16A34A), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(localBank!, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF15803D), fontSize: 13)),
                                  Text('${localBranch ?? ''} • ${localCity ?? ''}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF166534))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('user_bank_account', accountCtrl.text.trim());
                          await prefs.setString('user_bank_ifsc', ifscCtrl.text.trim().toUpperCase());
                          if (localBank != null) await prefs.setString('user_bank_name', localBank!);
                          if (localBranch != null) await prefs.setString('user_bank_branch', localBranch!);
                          if (localCity != null) await prefs.setString('user_bank_city', localCity!);

                          if (mounted) {
                            setState(() {
                              _bankAccountNumber = accountCtrl.text.trim();
                              _bankIfsc = ifscCtrl.text.trim().toUpperCase();
                              _bankName = localBank;
                              _bankBranch = localBranch;
                              _bankCity = localCity;
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: ReDoColors.primaryYellow,
                                content: Text('Bank account saved successfully.', style: GoogleFonts.inter(color: ReDoColors.darkNavy, fontWeight: FontWeight.w700)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ReDoColors.primaryYellow,
                          foregroundColor: ReDoColors.darkNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Bank Details', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 5. APPEARANCE SELECTOR
  // ===========================================================================
  void _showAppearanceSelector(BuildContext context) {
    final themeVM = context.read<ThemeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance Theme', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined, color: ReDoColors.primaryYellow),
              title: Text('Light Mode', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
              trailing: themeVM.themeMode == ThemeMode.light ? const Icon(Icons.check_circle, color: ReDoColors.primaryYellow) : null,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined, color: ReDoColors.primaryYellow),
              title: Text('Dark Mode', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
              trailing: themeVM.themeMode == ThemeMode.dark ? const Icon(Icons.check_circle, color: ReDoColors.primaryYellow) : null,
              onTap: () {
                themeVM.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest_outlined, color: ReDoColors.primaryYellow),
              title: Text('System Default', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
              trailing: themeVM.themeMode == ThemeMode.system ? const Icon(Icons.check_circle, color: ReDoColors.primaryYellow) : null,
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

  // ===========================================================================
  // 6. LANGUAGE SELECTOR (12 Indian Languages)
  // ===========================================================================
  void _showLanguageSelector(BuildContext context) {
    final themeVM = context.read<ThemeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;

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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select language', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isSelected = themeVM.locale.languageCode == lang['code'];
                  return ListTile(
                    dense: true,
                    title: Text(lang['name']!, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: textPrimary)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: ReDoColors.primaryYellow) : null,
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

  // ===========================================================================
  // 7. UNITS SELECTOR
  // ===========================================================================
  void _showUnitsSelector(BuildContext context) {
    final themeVM = context.read<ThemeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Units of Measurement', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.scale_rounded, color: ReDoColors.primaryYellow),
              title: Text('Metric (Kg, Ton, Km)', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
              trailing: themeVM.isMetric ? const Icon(Icons.check_circle, color: ReDoColors.primaryYellow) : null,
              onTap: () {
                themeVM.setUnits('Metric (Kg, Km)');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.straighten_rounded, color: ReDoColors.primaryYellow),
              title: Text('Imperial (Lbs, Miles)', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary)),
              trailing: !themeVM.isMetric ? const Icon(Icons.check_circle, color: ReDoColors.primaryYellow) : null,
              onTap: () {
                themeVM.setUnits('Imperial (Lbs, Miles)');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportProblemModal(BuildContext context) {
    final descCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report a Problem', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Describe any app, booking, or dispatch issue.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: InputDecoration(hintText: 'Explain the issue in detail...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (descCtrl.text.isNotEmpty) {
                      await SupabaseService.createSupportTicket('App Issue', descCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support ticket created.')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: ReDoColors.primaryYellow, foregroundColor: ReDoColors.darkNavy),
                  child: const Text('Submit Ticket', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 8. RESET PASSWORD MODAL (Functional Supabase Auth)
  // ===========================================================================
  void _showResetPasswordModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;
    final textMuted = isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText;

    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isUpdating = false;
    final email = SupabaseService.currentUser?.email ?? 'user@redo.com';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brandYellow.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_reset, color: Color(0xFFD97706), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Reset Password',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Account: $email',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Minimum 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setModalState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isUpdating
                            ? null
                            : () async {
                                final pass = newPassCtrl.text.trim();
                                final confirm = confirmPassCtrl.text.trim();
                                if (pass.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password must be at least 6 characters long.')),
                                  );
                                  return;
                                }
                                if (pass != confirm) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Passwords do not match. Please re-check.')),
                                  );
                                  return;
                                }
                                setModalState(() => isUpdating = true);
                                try {
                                  await Supabase.instance.client.auth.updateUser(
                                    UserAttributes(password: pass),
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Color(0xFF16A34A),
                                        content: Text('Password updated successfully!'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isUpdating = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Password update error: $e')),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ReDoColors.primaryYellow,
                          foregroundColor: ReDoColors.darkNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isUpdating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ReDoColors.darkNavy))
                            : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.email_outlined, size: 16),
                        label: const Text('Send Password Reset Link to Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () async {
                          try {
                            await Supabase.instance.client.auth.resetPasswordForEmail(email);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.slateDark,
                                  content: Text('Password reset link sent to $email'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Reset email error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 9. ACTIVE SESSIONS & TRUSTED DEVICES MODAL
  // ===========================================================================
  void _showActiveSessionsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;
    final textMuted = isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText;

    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;
    final deviceOS = Platform.operatingSystem.toUpperCase();
    final signInTime = session?.user.lastSignInAt != null
        ? session!.user.lastSignInAt!.substring(0, 10)
        : 'Active Now';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSigningOutOthers = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.devices_rounded, color: Color(0xFF16A34A), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Active Sessions',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage authorized devices and active authentication tokens.',
                  style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 16),

                // Current Device Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCanvas : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.smartphone_rounded, color: Color(0xFF16A34A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'This Device ($deviceOS)',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ACTIVE NOW',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Email: ${user?.email ?? "Signed in"}',
                              style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                            ),
                            Text(
                              'Last sign in: $signInTime',
                              style: GoogleFonts.inter(fontSize: 10, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Security info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCanvas : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Protected by Supabase PKCE OAuth & rotating JWT token authentication.',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sign Out All Other Devices Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.phonelink_erase_rounded, size: 18, color: ReDoColors.danger),
                    label: isSigningOutOthers
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ReDoColors.danger))
                        : const Text(
                            'Sign Out of All Other Devices',
                            style: TextStyle(fontWeight: FontWeight.w800, color: ReDoColors.danger),
                          ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ReDoColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSigningOutOthers
                        ? null
                        : () async {
                            setModalState(() => isSigningOutOthers = true);
                            try {
                              await Supabase.instance.client.auth.signOut(scope: SignOutScope.others);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: ReDoColors.darkNavy,
                                    content: Text('All other active sessions have been signed out.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSigningOutOthers = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  void _confirmLogout(BuildContext context, AuthViewModel auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out of ReDo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: ReDoColors.danger, foregroundColor: Colors.white),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkInk : ReDoColors.darkNavy;
    final textMuted = isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : ReDoColors.cardBorder;
    final scaffoldBg = isDark ? AppColors.darkCanvas : ReDoColors.warmBg;

    final profile = auth.profile;
    final email = SupabaseService.currentUser?.email ?? 'shipper@example.com';
    final name = (profile?.fullName != null && profile!.fullName.isNotEmpty)
        ? profile.fullName
        : ((profile?.companyName != null && profile!.companyName!.isNotEmpty)
            ? profile.companyName!
            : 'Shipper Business');

    final hasKyc = (profile?.gstin != null && profile!.gstin!.isNotEmpty) || (profile?.panNumber != null && profile!.panNumber!.isNotEmpty);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile & Settings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage account, business KYC, and preferences.',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  icon: Icon(Icons.notifications_none_rounded, color: textPrimary),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Profile User Card
            _buildProfileHeroCard(context, auth, name, email, profile, isDark),

            const SizedBox(height: 20),

            // Business & KYC Section
            _buildSectionHeader('Business & KYC', 'Compliance and verified shipper details.', textPrimary, textMuted),
            const SizedBox(height: 8),
            _buildCardGroup(cardBg, cardBorder, [
              _buildMenuTile(
                icon: Icons.badge_outlined,
                title: 'Business Details',
                subtitle: profile?.companyName ?? 'Add company, GSTIN & PAN',
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => _showEditProfileModal(context, auth),
              ),
              _buildDivider(isDark),
              _buildMenuTile(
                icon: Icons.verified_user_outlined,
                title: 'KYC Verification',
                subtitle: hasKyc ? 'Verified Shipper Business' : 'Upload GST/PAN verification document',
                badgeText: hasKyc ? 'VERIFIED' : 'PENDING',
                badgeColor: hasKyc ? const Color(0xFF16A34A) : ReDoColors.primaryYellow,
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycVerificationScreen())),
              ),
              _buildDivider(isDark),
              _buildMenuTile(
                icon: Icons.account_balance_outlined,
                title: 'Bank & Payout Details',
                subtitle: _bankName != null ? '$_bankName • $_bankIfsc' : 'Add account & auto-IFSC lookup',
                badgeText: _bankName != null ? 'LINKED' : null,
                badgeColor: const Color(0xFF16A34A),
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => _showBankAccountModal(context),
              ),
              _buildDivider(isDark),
              _buildMenuTile(
                icon: Icons.location_on_outlined,
                title: 'Saved Hubs & Addresses',
                subtitle: 'Google Places live suggestions',
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => _showSavedAddressesModal(context),
              ),
              _buildDivider(isDark),
              _buildMenuTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Wallet & ReDo Credits',
                subtitle: 'Manage payments, balance and freight credits',
                badgeText: '₹2,450',
                badgeColor: const Color(0xFFD97706),
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // Preferences & App Settings
            _buildSectionHeader('App Settings', 'Appearance, language and alerts.', textPrimary, textMuted),
            const SizedBox(height: 8),
            _buildCardGroup(cardBg, cardBorder, [
              _buildMenuTile(
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                subtitle: themeVM.themeMode == ThemeMode.dark
                    ? 'Dark Mode'
                    : (themeVM.themeMode == ThemeMode.light ? 'Light Mode' : 'System Default'),
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => _showAppearanceSelector(context),
              ),
              _buildDivider(isDark),
              _buildMenuTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: _getLanguageDisplayName(themeVM.locale.languageCode),
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => _showLanguageSelector(context),
              ),
              _buildDivider(isDark),
              _buildMenuTile(
                icon: Icons.straighten_rounded,
                title: 'Units of Measurement',
                subtitle: themeVM.selectedUnits,
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => _showUnitsSelector(context),
              ),
              _buildDivider(isDark),
              // Notifications Switch Tile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCanvas : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.notifications_active_outlined, size: 19, color: textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Push Notifications', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary)),
                          Text('Trip status, alerts & dispatch offers', style: GoogleFonts.inter(fontSize: 11, color: textMuted)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _pushNotifications,
                      activeThumbColor: ReDoColors.primaryYellow,
                      onChanged: _saveNotificationPref,
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // Security & Sessions (Password reset and active device management)
            _buildSectionHeader('Security & Sessions', 'Password management and active devices.', textPrimary, textMuted),
            const SizedBox(height: 8),
            _buildCardGroup(cardBg, cardBorder, [
              _buildMenuTile(
                icon: Icons.lock_reset_outlined,
                title: 'Reset Password',
                subtitle: 'Update account password or request email reset link',
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => _showResetPasswordModal(context),
              ),
              _buildDivider(isDark),
              _buildMenuTile(
                icon: Icons.devices_rounded,
                title: 'Active Sessions & Devices',
                subtitle: 'View trusted devices & terminate other sessions',
                badgeText: 'SECURE',
                badgeColor: const Color(0xFF16A34A),
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => _showActiveSessionsModal(context),
              ),
            ]),

            const SizedBox(height: 20),

            // Support & Legal
            _buildSectionHeader('Support & Legal', '24/7 assistance and compliance.', textPrimary, textMuted),
            const SizedBox(height: 8),
            _buildCardGroup(cardBg, cardBorder, [
              _buildMenuTile(
                icon: Icons.headset_mic_outlined,
                title: 'Customer Support',
                subtitle: 'Direct help with active shipments',
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
              ),
              _buildDivider(isDark),
              _buildMenuTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Report a Problem',
                subtitle: 'Submit support ticket to operations',
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () => _showReportProblemModal(context),
              ),
            ]),

            const SizedBox(height: 24),

            // Log Out Button
            _buildLogoutButton(context, auth, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard(
    BuildContext context,
    AuthViewModel auth,
    String name,
    String email,
    UserProfile? profile,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFFFE8B3)),
        boxShadow: [
          BoxShadow(
            color: ReDoColors.primaryYellow.withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openAvatarOptions(context, auth),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ReDoColors.primaryYellow, width: 2.5),
                  ),
                  child: ClipOval(child: _buildAvatarWidget(profile, 64)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 11, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkInk : ReDoColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? AppColors.darkInkMuted : ReDoColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    profile?.companyName?.isNotEmpty == true ? profile!.companyName! : 'Verified Shipper',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showEditProfileModal(context, auth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCanvas : const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFFFDE99)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 13, color: isDark ? AppColors.darkInk : ReDoColors.darkNavy),
                  const SizedBox(width: 4),
                  Text('Edit profile', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkInk : ReDoColors.darkNavy)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color textPrimary, Color textMuted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11, color: textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildCardGroup(Color cardBg, Color cardBorder, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCanvas : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: textMuted)),
                  ],
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? ReDoColors.primaryYellow).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badgeText, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor ?? ReDoColors.primaryYellow)),
                ),
              ],
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, thickness: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF3F4F6));
  }

  Widget _buildLogoutButton(BuildContext context, AuthViewModel auth, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFFEE2E2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _confirmLogout(context, auth),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, color: ReDoColors.danger, size: 18),
                const SizedBox(width: 8),
                Text('Log out', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: ReDoColors.danger)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'hi':
        return 'हिंदी (Hindi)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      case 'te':
        return 'తెలుగు (Telugu)';
      case 'kn':
        return 'ಕನ್ನಡ (Kannada)';
      case 'mr':
        return 'मराठी (Marathi)';
      case 'gu':
        return 'ગુજરાતી (Gujarati)';
      case 'pa':
        return 'ਪੰਜਾਬੀ (Punjabi)';
      case 'bn':
        return 'বাংলা (Bengali)';
      case 'or':
        return 'ଓଡ଼ିଆ (Odia)';
      case 'ml':
        return 'മലയാളം (Malayalam)';
      case 'ur':
        return 'اردو (Urdu)';
      default:
        return 'English';
    }
  }
}
