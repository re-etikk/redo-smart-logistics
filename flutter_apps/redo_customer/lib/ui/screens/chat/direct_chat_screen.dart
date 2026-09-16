import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../data/services/supabase_service.dart';

class DirectChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderName;
  final String text;
  final String? imagePath;
  final DateTime timestamp;
  final bool isMe;

  DirectChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imagePath,
    required this.timestamp,
    required this.isMe,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'sender_id': senderId,
        'sender_name': senderName,
        'text': text,
        'image_path': imagePath,
        'timestamp': timestamp.toIso8601String(),
        'is_me': isMe,
      };

  factory DirectChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final sender = json['sender_id'] ?? '';
    return DirectChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      bookingId: json['booking_id'] ?? '',
      senderId: sender,
      senderName: json['sender_name'] ?? 'Partner',
      text: json['text'] ?? '',
      imagePath: json['image_path'] ?? json['image_url'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      isMe: json['is_me'] ?? (sender == currentUserId),
    );
  }
}

class DirectChatScreen extends StatefulWidget {
  final String bookingId;
  final String counterpartyName;
  final String counterpartyRole;
  final String counterpartyPhone;
  final String? truckReg;
  final String origin;
  final String destination;

  const DirectChatScreen({
    super.key,
    required this.bookingId,
    required this.counterpartyName,
    this.counterpartyRole = 'Driver',
    required this.counterpartyPhone,
    this.truckReg,
    required this.origin,
    required this.destination,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final List<DirectChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  RealtimeChannel? _chatChannel;
  File? _selectedImage;
  bool _sending = false;

  final List<String> _quickChips = [
    'Reached pickup warehouse 📍',
    'Loading is in progress 📦',
    'Share exact gate / dock number 🚪',
    'Toll traffic delay (~15 mins) ⏳',
    'Unloaded & receipt signed ✅',
  ];

  @override
  void initState() {
    super.initState();
    _loadPersistedMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    if (_chatChannel != null) {
      SupabaseService.removeChannel(_chatChannel!);
    }
    super.dispose();
  }

  String get _storageKey => 'redo_direct_chat_${widget.bookingId}';

  Future<void> _loadPersistedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_storageKey);
    final myId = SupabaseService.currentUser?.id ?? 'me';

    if (cached != null) {
      try {
        final List list = jsonDecode(cached);
        setState(() {
          _messages.clear();
          _messages.addAll(list.map((e) => DirectChatMessage.fromJson(e, myId)));
        });
      } catch (_) {}
    }

    // Attempt to fetch from Supabase
    try {
      final rows = await SupabaseService.client
          .from('booking_messages')
          .select()
          .eq('booking_id', widget.bookingId)
          .order('created_at', ascending: true);

      if (rows.isNotEmpty) {
        setState(() {
          _messages.clear();
          _messages.addAll(rows.map((e) => DirectChatMessage.fromJson(e, myId)));
        });
        _persistMessages();
      }
    } catch (_) {}

    _scrollToBottom();
  }

  Future<void> _persistMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _messages.map((m) => m.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  void _subscribeRealtime() {
    final myId = SupabaseService.currentUser?.id ?? 'me';
    try {
      _chatChannel = SupabaseService.client.channel('chat-${widget.bookingId}');
      _chatChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'booking_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'booking_id',
          value: widget.bookingId,
        ),
        callback: (payload) {
          final newRecord = payload.newRecord;
          if (newRecord['sender_id'] != myId) {
            final msg = DirectChatMessage.fromJson(newRecord, myId);
            setState(() => _messages.add(msg));
            _persistMessages();
            _scrollToBottom();
          }
        },
      );
      _chatChannel!.subscribe();
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final myId = SupabaseService.currentUser?.id ?? 'me';
    final myName = SupabaseService.currentUser?.userMetadata?['full_name'] ?? 'Me';

    final message = DirectChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookingId: widget.bookingId,
      senderId: myId,
      senderName: myName,
      text: text,
      imagePath: _selectedImage?.path,
      timestamp: DateTime.now(),
      isMe: true,
    );

    setState(() {
      _messages.add(message);
      if (quickText == null) _textController.clear();
      _selectedImage = null;
      _sending = true;
    });

    _persistMessages();
    _scrollToBottom();

    // Push to Supabase if table exists
    try {
      await SupabaseService.client.from('booking_messages').insert({
        'booking_id': widget.bookingId,
        'sender_id': myId,
        'sender_name': myName,
        'text': text,
        'image_url': message.imagePath,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    setState(() => _sending = false);
  }

  Future<void> _makeCall() async {
    final clean = widget.counterpartyPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot launch call to $clean')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final cardBg = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.brandYellow,
              child: Text(
                widget.counterpartyName.isNotEmpty ? widget.counterpartyName[0].toUpperCase() : 'P',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slateDark),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.counterpartyName,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.counterpartyRole}${widget.truckReg != null ? " • ${widget.truckReg}" : ""}',
                        style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.success),
            tooltip: 'Call Direct',
            onPressed: _makeCall,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Consignment Corridor Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.brandYellowDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Booking #${widget.bookingId.length > 8 ? widget.bookingId.substring(0, 8).toUpperCase() : widget.bookingId} • ${widget.origin} → ${widget.destination}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Message Stream
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'Direct Coordination Active',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Send loading updates, dock directions or document photos.',
                          style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      return _buildMessageBubble(m, isDark);
                    },
                  ),
          ),

          // Selected Image Preview Thumbnail
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: cardBg,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Text('Document attached', style: GoogleFonts.inter(fontSize: 12, color: textPrimary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          // Quick Action Coordination Chips
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final chip = _quickChips[i];
                return ActionChip(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  side: BorderSide(color: cardBorder),
                  label: Text(
                    chip,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  onPressed: () => _sendMessage(chip),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: AppColors.brandYellowDark),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  IconButton(
                    icon: Icon(Icons.photo_outlined, color: textMuted),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type coordinate message...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: textMuted),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: cardBorder)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.brandYellow,
                    radius: 20,
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slateDark),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.slateDark),
                            onPressed: () => _sendMessage(),
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

  Widget _buildMessageBubble(DirectChatMessage m, bool isDark) {
    final timeStr = DateFormat('hh:mm a').format(m.timestamp);

    return Align(
      alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: m.isMe
              ? AppColors.brandYellow
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.isMe ? 16 : 4),
            bottomRight: Radius.circular(m.isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: m.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (m.imagePath != null && File(m.imagePath!).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(m.imagePath!), height: 160, fit: BoxFit.cover),
              ),
              const SizedBox(height: 6),
            ],
            if (m.text.isNotEmpty)
              Text(
                m.text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: m.isMe ? AppColors.slateDark : (isDark ? Colors.white : AppColors.slateDark),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: m.isMe ? AppColors.slateDark.withValues(alpha: 0.7) : AppColors.inkMuted,
                  ),
                ),
                if (m.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, size: 12, color: AppColors.slateDark.withValues(alpha: 0.7)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
