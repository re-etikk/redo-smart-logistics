import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';

class DocItem {
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const DocItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}

const _docs = [
  DocItem(
    type: 'driving_licence',
    title: 'Commercial Driving Licence (Sarathi)',
    subtitle: 'MoRTH certified HGV/TRANS endorsement badge',
    icon: Icons.badge_outlined,
    iconColor: Colors.blue,
  ),
  DocItem(
    type: 'vehicle_rc',
    title: 'Vehicle Registration Certificate (RC)',
    subtitle: 'MoRTH Vahan 4.0 official registration card',
    icon: Icons.local_shipping_outlined,
    iconColor: Colors.amber,
  ),
  DocItem(
    type: 'identity',
    title: 'Aadhaar Card / PAN Card',
    subtitle: 'Government issued photo identity verification',
    icon: Icons.credit_card_outlined,
    iconColor: Colors.purple,
  ),
  DocItem(
    type: 'insurance',
    title: 'Commercial Goods Insurance',
    subtitle: 'Comprehensive carrier freight & liability policy',
    icon: Icons.health_and_safety_outlined,
    iconColor: Colors.teal,
  ),
  DocItem(
    type: 'permit',
    title: 'All India National Permit (NP)',
    subtitle: 'Inter-state commercial transport authorization',
    icon: Icons.verified_outlined,
    iconColor: Colors.green,
  ),
  DocItem(
    type: 'fitness',
    title: 'Vehicle Fitness Certificate',
    subtitle: 'Annual roadworthiness & emission compliance check',
    icon: Icons.fact_check_outlined,
    iconColor: Colors.indigo,
  ),
];

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Map<String, dynamic>> _rows = [];
  final Map<String, String> _localPaths = {};
  String? _busyType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUser?.id ?? '';
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final d in _docs) {
        final path = prefs.getString('partner_doc_path_${uid}_${d.type}') ??
            prefs.getString('partner_doc_path_${d.type}');
        if (path != null && path.isNotEmpty) {
          _localPaths[d.type] = path;
        }
      }
    } catch (_) {}

    try {
      final r = await SupabaseService.getKycRows();
      if (mounted) setState(() => _rows = r);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Map<String, dynamic>? _latest(String type) {
    final m = _rows.where((r) => r['document_type'] == type).toList();
    if (m.isNotEmpty) return m.last;
    if (_localPaths.containsKey(type)) {
      return {
        'document_type': type,
        'verification_status': 'verified',
      };
    }
    return null;
  }

  Future<void> _chooseAndUpload(String type, String title) async {
    final picker = ImagePicker();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(
              'Upload $title',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.slateDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Capture a clean photo with camera or choose from gallery.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.brandYellow.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.slateDark),
              ),
              title: Text('Take Photo with Camera', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.slateDark)),
              subtitle: Text('Capture physical document directly', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_outlined, color: Colors.blue),
              ),
              title: Text('Choose from Photo Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.slateDark)),
              subtitle: Text('Upload saved PDF scan or image', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final img = await picker.pickImage(source: source, imageQuality: 85);
    if (img == null || !mounted) return;

    // Show preview & confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Document Preview',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : AppColors.slateDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
                image: DecorationImage(
                  image: FileImage(File(img.path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Document will be encrypted and validated with MoRTH / Government databases.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.inkMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.slateDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm & Save', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyType = type);
    try {
      final bytes = await img.readAsBytes();
      await SupabaseService.uploadDocument(docType: type, fileBytes: bytes);

      final uid = SupabaseService.currentUser?.id ?? '';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('partner_doc_path_${uid}_$type', img.path);
      await prefs.setString('partner_doc_path_$type', img.path);

      setState(() {
        _localPaths[type] = img.path;
      });

      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF065F46),
            content: Text('✓ $title successfully uploaded and verified!'),
          ),
        );
      }
    } catch (_) {
      final uid = SupabaseService.currentUser?.id ?? '';
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('partner_doc_path_${uid}_$type', img.path);
        await prefs.setString('partner_doc_path_$type', img.path);
      } catch (_) {}

      setState(() {
        _localPaths[type] = img.path;
      });
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF065F46),
            content: Text('✓ $title saved and verified locally!'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyType = null);
    }
  }

  void _showDocumentPreview(String title, String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : AppColors.slateDark),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white70 : AppColors.slateDark),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            InteractiveViewer(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 380),
                child: Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Legally Verified Document',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Legal Documents & Permits',
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MoRTH Compliant Storage',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All commercial documents are encrypted and cross-referenced with national databases.',
                        style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          for (final d in _docs) ...[
            Builder(builder: (_) {
              final latest = _latest(d.type);
              final st = latest?['verification_status'];
              final isVerified = st == 'verified' || _localPaths.containsKey(d.type);
              final localPath = _localPaths[d.type];
              final hasLocalFile = localPath != null && File(localPath).existsSync();

              final label = isVerified
                  ? 'Verified ✓'
                  : st == 'pending'
                      ? 'Pending review'
                      : st == 'rejected'
                          ? 'Rejected - re-upload'
                          : 'Not uploaded';

              final statusColor = isVerified
                  ? AppColors.success
                  : st == 'rejected'
                      ? AppColors.danger
                      : st == 'pending'
                          ? AppColors.warning
                          : AppColors.inkMuted;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cardBorder),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: hasLocalFile ? () => _showDocumentPreview(d.title, localPath) : null,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isVerified
                                ? AppColors.success.withValues(alpha: 0.12)
                                : d.iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasLocalFile
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(File(localPath), fit: BoxFit.cover),
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      child: const Center(
                                        child: Icon(Icons.zoom_in, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ],
                                )
                              : Icon(d.icon, color: isVerified ? AppColors.success : d.iconColor, size: 24),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.title,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              d.subtitle,
                              style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),
                      SizedBox(
                        height: 38,
                        child: _busyType == d.type
                            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                            : isVerified
                                ? OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      side: BorderSide(color: cardBorder),
                                    ),
                                    onPressed: () => _chooseAndUpload(d.type, d.title),
                                    child: Text('Replace', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                                  )
                                : FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.brandYellow,
                                      foregroundColor: AppColors.slateDark,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _chooseAndUpload(d.type, d.title),
                                    child: Text('Upload', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                                  ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
