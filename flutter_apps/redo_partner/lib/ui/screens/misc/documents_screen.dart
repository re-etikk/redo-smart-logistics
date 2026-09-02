import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/ui_components.dart';

const _docs = [
  ('driving_licence', 'Commercial Driving Licence'),
  ('vehicle_rc', 'Vehicle RC'),
  ('identity', 'Aadhaar / PAN'),
  ('insurance', 'Insurance Certificate'),
  ('permit', 'National Permit'),
  ('fitness', 'Fitness Certificate'),
];

/// KYC status + re-upload. Files go to the private bucket; the admin console
/// (website) verifies and the driver gets a notification on the decision.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Map<String, dynamic>> _rows = [];
  String? _busyType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await SupabaseService.getKycRows();
      if (mounted) setState(() => _rows = r);
    } catch (_) {}
  }

  Map<String, dynamic>? _latest(String type) {
    final m = _rows.where((r) => r['document_type'] == type).toList();
    return m.isEmpty ? null : m.last;
  }

  Future<void> _upload(String type) async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (img == null) return;
    setState(() => _busyType = type);
    try {
      final bytes = await img.readAsBytes();
      await SupabaseService.uploadDocument(docType: type, fileBytes: bytes);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Uploaded - pending admin review, you will be notified.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
    if (mounted) setState(() => _busyType = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('KYC Documents')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
              'Private bucket storage - only masked references are kept on record.',
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted)),
          const SizedBox(height: 12),
          for (final d in _docs)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.$2,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Builder(builder: (_) {
                            final st = _latest(d.$1)?['verification_status'];
                            final label = st == 'verified'
                                ? 'Verified ✓'
                                : st == 'pending'
                                    ? 'Pending review'
                                    : st == 'rejected'
                                        ? 'Rejected - re-upload'
                                        : 'Not uploaded';
                            final color = st == 'verified'
                                ? AppColors.success
                                : st == 'rejected'
                                    ? AppColors.danger
                                    : st == 'pending'
                                        ? AppColors.warning
                                        : AppColors.inkMuted;
                            return Text(label,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color));
                          }),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: RedoButton(
                        title: _busyType == d.$1
                            ? '…'
                            : _latest(d.$1) != null
                                ? 'Replace'
                                : 'Upload',
                        isSecondary: true,
                        onPressed:
                            _busyType == d.$1 ? null : () => _upload(d.$1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
