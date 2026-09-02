import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';

/// Live notifications — booking accepted/confirmed, KYC decisions, etc.
/// New rows arrive via Supabase Realtime, Rapido-style: no refresh needed.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>>? _items;
  RealtimeChannel? _ch;

  @override
  void initState() {
    super.initState();
    _load();
    _ch = SupabaseService.subscribeNotifications(_load);
  }

  @override
  void dispose() {
    if (_ch != null) SupabaseService.removeChannel(_ch!);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final v = await SupabaseService.getNotifications();
      if (mounted) setState(() => _items = v);
    } catch (_) {
      if (mounted) setState(() => _items ??= []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items ?? [];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _items != null && items.isEmpty
            ? ListView(children: [
                const SizedBox(height: 120),
                const Icon(Icons.notifications_none,
                    size: 48, color: AppColors.inkMuted),
                const SizedBox(height: 12),
                Center(
                    child: Text('Nothing here yet.',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.w700))),
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = items[i];
                  final read = n['read'] == true;
                  String when = '';
                  final t =
                      DateTime.tryParse('${n['created_at']}')?.toLocal();
                  if (t != null) {
                    when = DateFormat('d MMM, h:mm a').format(t);
                  }
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                          color: read
                              ? AppColors.border
                              : AppColors.brandYellow,
                          width: read ? 1 : 1.6),
                    ),
                    child: ListTile(
                      onTap: () async {
                        if (!read) {
                          try {
                            await SupabaseService
                                .markNotificationRead('${n['id']}');
                            _load();
                          } catch (_) {}
                        }
                      },
                      title: Text('${n['title'] ?? ''}',
                          style: GoogleFonts.inter(
                              fontWeight:
                                  read ? FontWeight.w600 : FontWeight.w900)),
                      subtitle: Text('${n['body'] ?? ''}\n$when',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.inkMuted)),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// AppBar bell with LIVE unread badge — drop into any screen's actions.
class NotificationsBell extends StatefulWidget {
  const NotificationsBell({super.key});

  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  int _unread = 0;
  RealtimeChannel? _ch;

  @override
  void initState() {
    super.initState();
    _refresh();
    _ch = SupabaseService.subscribeNotifications(_refresh);
  }

  @override
  void dispose() {
    if (_ch != null) SupabaseService.removeChannel(_ch!);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final n = await SupabaseService.getNotifications();
      if (mounted) {
        setState(() => _unread = n.where((x) => x['read'] != true).length);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      IconButton(
        icon: const Icon(Icons.notifications_none),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ).then((_) => _refresh()),
      ),
      if (_unread > 0)
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(999)),
            child: Text('$_unread',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slateDark)),
          ),
        ),
    ]);
  }
}
