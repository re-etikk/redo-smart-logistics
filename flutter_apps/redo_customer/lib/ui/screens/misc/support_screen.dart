import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';
import '../../widgets/ui_components.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<Map<String, dynamic>>? _tickets;
  final _subject = TextEditingController();
  final _desc = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await SupabaseService.getSupportTickets();
      if (mounted) setState(() => _tickets = v);
    } catch (_) {
      if (mounted) setState(() => _tickets ??= []);
    }
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await SupabaseService.createSupportTicket(
          _subject.text.trim(), _desc.text.trim());
      _subject.clear();
      _desc.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ticket raised - our team will respond soon.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _tickets ?? [];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Raise a ticket',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _subject,
                      decoration: const InputDecoration(
                          hintText: 'Subject — what do you need help with?')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _desc,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(hintText: 'Details (optional)')),
                  const SizedBox(height: 14),
                  RedoButton(
                      title: _busy ? 'Submitting…' : 'Submit Ticket',
                      onPressed: _busy ? null : _submit),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('My tickets',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (_tickets != null && tickets.isEmpty)
            Text('No tickets yet.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.inkMuted)),
          for (final t in tickets)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('${t['subject']}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                subtitle: Text(
                    'Status: ${'${t['status'] ?? 'open'}'.replaceAll('_', ' ')}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.inkMuted)),
                trailing: Icon(
                  (t['status'] == 'resolved' || t['status'] == 'closed')
                      ? Icons.check_circle
                      : Icons.pending_outlined,
                  color: (t['status'] == 'resolved' || t['status'] == 'closed')
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
