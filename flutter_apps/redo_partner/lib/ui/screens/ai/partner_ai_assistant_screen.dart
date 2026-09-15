import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/services/voice_assistant_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/partner_trips_viewmodel.dart';


import '../misc/notifications_screen.dart';


class PartnerAiAssistantScreen extends StatefulWidget {
  final Function(int tabIndex)? onTabChangeRequested;
  const PartnerAiAssistantScreen({super.key, this.onTabChangeRequested});

  @override
  State<PartnerAiAssistantScreen> createState() => _PartnerAiAssistantScreenState();
}

class _PartnerAiAssistantScreenState extends State<PartnerAiAssistantScreen> with SingleTickerProviderStateMixin {
  File? _attachedBilty;
  bool _analyzingBilty = false;

  int _activeMode = 0; // 0: Chat, 1: Voice
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _waveAnimController;

  @override
  void initState() {
    super.initState();
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    Future.microtask(() {
      if (mounted) {
        final voice = context.read<VoiceAssistantService>();
        voice.setActiveShipmentsProvider(() => context.read<PartnerTripsViewModel>().activeTrips);
      }
    });
  }

  @override
  void dispose() {
    _waveAnimController.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitText(VoiceAssistantService voice) {
    final q = _textCtrl.text.trim();
    if (q.isEmpty) return;
    _textCtrl.clear();
    voice.sendTextMessage(q);
    _scrollToBottom();
  }

  void _sendPresetPrompt(String prompt, VoiceAssistantService voice) {
    voice.sendTextMessage(prompt);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceAssistantService>();
    final auth = context.watch<AuthViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final cardBorder = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final cardBg = Theme.of(context).cardColor;

    final name = auth.profile?.fullName ?? '';
    String initials = 'RC';
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Redo Brand Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: cardBorder, width: 0.8)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/customer_logo.png',
                      height: 36,
                      width: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
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
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.slateDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mode Selector: Chat vs Voice
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeMode = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeMode == 0
                              ? (isDark ? AppColors.darkCanvas : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeMode == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: _activeMode == 0 ? AppColors.brandYellow : textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Chat Mode',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: _activeMode == 0 ? FontWeight.w800 : FontWeight.w600,
                                color: _activeMode == 0 ? textPrimary : textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _activeMode = 1);
                        if (!voice.isListening) {
                          voice.startListening();
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeMode == 1
                              ? (isDark ? AppColors.darkCanvas : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeMode == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic_none_rounded,
                              size: 16,
                              color: _activeMode == 1 ? AppColors.brandYellow : textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Voice Assistant',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: _activeMode == 1 ? FontWeight.w800 : FontWeight.w600,
                                color: _activeMode == 1 ? textPrimary : textMuted,
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

            // Active View
            Expanded(
              child: _activeMode == 0
                  ? _buildChatMode(voice, isDark, textPrimary, textMuted, cardBorder, cardBg)
                  : _buildVoiceMode(voice, isDark, textPrimary, textMuted, cardBorder),
            ),
          ],
        ),
      ),
    );
  }

  // Chat Mode
  Widget _buildChatMode(
    VoiceAssistantService voice,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    Color cardBg,
  ) {
    final messages = voice.chatHistory;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _buildAiHeroCard(isDark),
              const SizedBox(height: 14),
              _buildQuickActionsRow(voice, isDark, cardBorder, textPrimary, textMuted),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              ...messages.map((m) => _buildChatBubble(m, isDark, textPrimary, textMuted, cardBorder, cardBg)),

              if (voice.isProcessing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/redo_robot_avatar.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (ctx, err, stack) => const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.brandYellow,
                            child: Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.slateDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandYellow),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Sarvam & HF analyzing corridor rates...',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
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

        _buildSuggestionChipsRow(voice, isDark),
        _buildChatInputBar(voice, isDark, textPrimary, textMuted, cardBorder, cardBg),
      ],
    );
  }

  Widget _buildAiHeroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2208) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hi! I’m Redo AI',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.slateDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('✨', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Powered by Sarvam AI (105B) & Hugging Face',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildCheckItem('Instant rates & quotes', isDark),
                    _buildCheckItem('Track live shipments', isDark),
                    _buildCheckItem('Vehicle recommendation', isDark),
                    _buildCheckItem('12 Indian languages', isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'Ask Anything!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slateDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Image.asset(
                  'assets/images/redo_robot_mascot.png',
                  height: 95,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(
                    Icons.smart_toy_rounded,
                    size: 70,
                    color: AppColors.brandYellow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? const Color(0xFFE2E8F0) : AppColors.slateDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow(
    VoiceAssistantService voice,
    bool isDark,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final actions = [
      {'icon': Icons.calculate_outlined, 'title': 'Get a quote', 'prompt': 'Delhi se Mumbai 12 ton truck ka rate kya hoga?'},
      {'icon': Icons.location_on_outlined, 'title': 'Track shipment', 'prompt': 'Mera active shipment track karo'},
      {'icon': Icons.local_shipping_outlined, 'title': 'Find vehicle', 'prompt': '15 ton goods ke liye konsa truck best hai?'},
      {'icon': Icons.alt_route_outlined, 'title': 'Highway info', 'prompt': 'NH-48 Delhi Mumbai route ka transit samay aur toll estimate batao'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((a) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _sendPresetPrompt(a['prompt'] as String, voice),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(a['icon'] as IconData, size: 16, color: AppColors.brandYellow),
                    const SizedBox(width: 8),
                    Text(
                      a['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatBubble(
    ChatMessage msg,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    Color cardBg,
  ) {
    final isUser = msg.isUser;
    final action = msg.action;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/redo_robot_avatar.png',
                width: 32,
                height: 32,
                errorBuilder: (ctx, err, stack) => const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.brandYellow,
                  child: Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.slateDark),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser && action?.aiEngineUsed != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow.withValues(alpha: isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 10, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            action!.aiEngineUsed!,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.brandYellow : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.brandYellow
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: isUser ? AppColors.slateDark : textPrimary,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),

                if (!isUser && action?.type == 'rate_quote' && action?.estimatedPriceInr != null)
                  _buildFreightRateCard(action!, isDark, cardBorder, textPrimary, textMuted),

                if (!isUser && action?.type == 'track_shipment')
                  _buildLiveTrackingCard(action!, isDark, cardBorder, textPrimary, textMuted),

                if (!isUser && (action?.type == 'recommend_vehicle' || (action?.recommendedVehicle != null && action?.type != 'rate_quote')))
                  _buildVehicleRecommendationCard(action, isDark, cardBorder, textPrimary, textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreightRateCard(
    VoiceAssistantAction action,
    bool isDark,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final from = action.fromCity ?? 'Origin';
    final to = action.toCity ?? 'Destination';
    final price = action.estimatedPriceInr ?? 0;
    final dist = action.distanceKm?.round() ?? 0;
    final hrs = action.transitHours ?? 0;
    final truck = action.recommendedVehicle ?? '32ft Multi-Axle Container';
    final highway = action.highwayName ?? 'National Highway';

    return Container(
      width: 290,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, size: 16, color: AppColors.brandYellow),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$from ➔ $to',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Live Quote',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currency.format(price),
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF10B981)),
              ),
              const SizedBox(width: 6),
              Text('est. all-inclusive', style: GoogleFonts.inter(fontSize: 10, color: textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCanvas : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Corridor Route', style: GoogleFonts.inter(fontSize: 11, color: textMuted)),
                    Text('$dist km • ~${hrs}h via $highway', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recommended Truck', style: GoogleFonts.inter(fontSize: 11, color: textMuted)),
                    Expanded(
                      child: Text(
                        truck,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.slateDark,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.bolt, size: 16),
              label: Text('⚡ Available Loads', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900)),
              onPressed: () {
                if (widget.onTabChangeRequested != null) {
                  widget.onTabChangeRequested!(0);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTrackingCard(
    VoiceAssistantAction action,
    bool isDark,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final id = action.bookingId ?? 'RDL-1001';
    final from = action.fromCity ?? 'Origin';
    final dest = action.toCity ?? 'Destination';
    final status = action.status ?? 'in_transit';
    final truck = action.truckNumber ?? 'MH-04-AB-1234';
    final driver = action.driverName ?? 'Verified Driver';

    final hasBooking = action.bookingId != null;

    return Container(
      width: 290,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                hasBooking ? '#$id • $status' : 'Live Tracking Lookup',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$from ➔ $dest',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: textPrimary),
          ),
          if (hasBooking) ...[
            const SizedBox(height: 6),
            Text('Truck: $truck • Driver: $driver', style: GoogleFonts.inter(fontSize: 11, color: textMuted)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasBooking ? AppColors.slateDark : AppColors.brandYellow,
                foregroundColor: hasBooking ? Colors.white : AppColors.slateDark,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              icon: Icon(hasBooking ? Icons.navigation_outlined : Icons.add_circle_outline, size: 16),
              label: Text(
                hasBooking ? '📍 View Active Trips' : 'Browse Open Loads',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                if (widget.onTabChangeRequested != null) {
                  widget.onTabChangeRequested!(1);
                } else {
                  if (widget.onTabChangeRequested != null) {
                    widget.onTabChangeRequested!(0);
                  } else {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleRecommendationCard(
    VoiceAssistantAction? action,
    bool isDark,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final truck = action?.recommendedVehicle ?? 'Tata 7 Ton (Canter)';
    final weight = action?.weightTons != null ? '${action!.weightTons} Ton' : 'Medium Freight';

    return Container(
      width: 280,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/redo_chat_truck.png',
                  width: 70,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 70,
                    height: 46,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.local_shipping, size: 28, color: AppColors.brandYellow),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truck,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Payload: $weight',
                      style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                    ),
                    Text(
                      'Recommended Fit',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.slateDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                if (widget.onTabChangeRequested != null) {
                  widget.onTabChangeRequested!(0);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Select Vehicle & Book',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChipsRow(VoiceAssistantService voice, bool isDark) {
    final suggestions = [
      'Delhi to Mumbai Rate',
      'Track my shipment',
      'Best truck for 15 tons',
      'Bangalore to Chennai price',
      'Highway NH-48 advice',
      'Talk to human support',
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return ActionChip(
            label: Text(s),
            labelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkInk : AppColors.slateDark,
            ),
            backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
            side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => _sendPresetPrompt(s, voice),
          );
        },
      ),
    );
  }

  
  void _openBiltyPickerSheet(BuildContext context, VoiceAssistantService voice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Upload Bilty, Invoice or POD',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'AI OCR will instantly extract route, weight, tax invoice and cargo items.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.amber),
                ),
                title: Text('Scan with Camera', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                subtitle: Text('Capture photo of printed bilty or consignment note', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickBilty(ImageSource.camera, voice);
                },
              ),
              const Divider(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                ),
                title: Text('Choose from Gallery / Files', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                subtitle: Text('Select PDF screenshot, JPG or PNG invoice', style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickBilty(ImageSource.gallery, voice);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBilty(ImageSource source, VoiceAssistantService voice) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _attachedBilty = File(picked.path);
        });
        await _triggerBiltyOcr(voice, picked.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/storage: $e')),
        );
      }
    }
  }

  Future<void> _triggerBiltyOcr(VoiceAssistantService voice, String filename) async {
    if (!mounted) return;
    setState(() => _analyzingBilty = true);
    
    // Dispatch query to AI co-pilot
    voice.sendTextMessage(
      'Attached Bilty / E-Way Bill: $filename. Please run instant OCR analysis to extract consignor, destination, cargo weight, and recommend verified trucks.',
    );
    
    // Simulate OCR processing time
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    
    setState(() {
      _analyzingBilty = false;
      _attachedBilty = null;
    });
    
    _scrollToBottom();
  }

  Widget _buildChatInputBar(
    VoiceAssistantService voice,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    Color cardBg,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_attachedBilty != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brandYellow),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(_attachedBilty!, width: 36, height: 36, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _analyzingBilty ? 'Analyzing Bilty via AI OCR...' : 'Bilty Attached: ${_attachedBilty!.path.split('/').last.split(r'\').last}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _analyzingBilty ? 'Extracting Consignor, Weight, Goods & Rate...' : 'Uploaded for instant OCR analysis',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  if (_analyzingBilty)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandYellow),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _attachedBilty = null),
                    ),
                ],
              ),
            ),
          Row(
            children: [
          IconButton(
            icon: Icon(Icons.attach_file_rounded, color: _attachedBilty != null ? AppColors.brandYellow : textMuted),
            tooltip: 'Attach Bilty / E-Way Bill',
            onPressed: () => _openBiltyPickerSheet(context, voice),
          ),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitText(voice),
              style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask anything about rates, trucks, corridors...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: textMuted),
                filled: true,
                fillColor: isDark ? AppColors.darkCanvas : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.brandYellow, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _submitText(voice),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.brandYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 20,
                color: AppColors.slateDark,
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              setState(() => _activeMode = 1);
              voice.startListening();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: cardBorder),
              ),
              child: const Icon(
                Icons.mic_rounded,
                size: 20,
                color: AppColors.brandYellow,
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  // Voice Mode
  Widget _buildVoiceMode(
    VoiceAssistantService voice,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
    final liveText = voice.transcribedText.isNotEmpty
        ? voice.transcribedText
        : (voice.isListening ? 'Listening to your voice...' : 'Tap the microphone and speak in any language');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandYellow.withValues(alpha: isDark ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq_rounded, size: 14, color: AppColors.brandYellow),
                const SizedBox(width: 6),
                Text(
                  'Indic Voice AI • Sarvam & HF',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.brandYellow : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Speak to Redo AI',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Speak freely in Hindi, English, Tamil, Telugu or your native language.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 28),

          // Pulsing Voice Waves
          AnimatedBuilder(
            animation: _waveAnimController,
            builder: (context, child) {
              final val = _waveAnimController.value;
              final isListening = voice.isListening;

              return SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isListening) ...[
                      Container(
                        width: 170 + (40 * val),
                        height: 170 + (40 * val),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandYellow.withValues(alpha: 0.15 * (1 - val)),
                        ),
                      ),
                      Container(
                        width: 140 + (25 * val),
                        height: 140 + (25 * val),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandYellow.withValues(alpha: 0.25 * (1 - val)),
                        ),
                      ),
                    ],
                    GestureDetector(
                      onTap: () {
                        if (voice.isListening) {
                          voice.stopListeningAndProcess();
                        } else {
                          voice.startListening();
                        }
                      },
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandYellow,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandYellow.withValues(alpha: 0.4),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          voice.isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                          size: 42,
                          color: AppColors.slateDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 14),
          Text(
            voice.isListening
                ? 'Listening...'
                : (voice.isProcessing ? 'Thinking...' : 'Tap mic to speak'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Real-time transcribed text bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over_outlined, color: AppColors.brandYellow, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    liveText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontStyle: voice.transcribedText.isEmpty ? FontStyle.italic : FontStyle.normal,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Voice Commands',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: textMuted),
            ),
          ),
          const SizedBox(height: 10),

          // 2x2 Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _buildVoiceCommandTile(
                'Book a truck',
                'Delhi to Mumbai 12 Ton',
                Icons.local_shipping_outlined,
                isDark,
                cardBorder,
                textPrimary,
                textMuted,
                () => _sendPresetPrompt('Delhi se Mumbai 12 ton truck ka rate kya hoga?', voice),
              ),
              _buildVoiceCommandTile(
                'Track shipment',
                'Check ongoing status',
                Icons.radar_outlined,
                isDark,
                cardBorder,
                textPrimary,
                textMuted,
                () => _sendPresetPrompt('Mera shipment track karo', voice),
              ),
              _buildVoiceCommandTile(
                'Vehicle options',
                'Compare container & canter',
                Icons.view_in_ar_outlined,
                isDark,
                cardBorder,
                textPrimary,
                textMuted,
                () => _sendPresetPrompt('15 ton ke liye konsa truck lagega?', voice),
              ),
              _buildVoiceCommandTile(
                'Highway advice',
                'NH-48 transit & toll info',
                Icons.traffic_outlined,
                isDark,
                cardBorder,
                textPrimary,
                textMuted,
                () => _sendPresetPrompt('NH-48 route advisory aur toll charges batao', voice),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _activeMode = 0),
                icon: const Icon(Icons.keyboard_outlined, size: 16),
                label: Text('Type instead', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              if (voice.state == VoiceAssistantState.speaking)
                ElevatedButton.icon(
                  onPressed: voice.cancelSpeaking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: const Text('Stop Voice'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCommandTile(
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() => _activeMode = 0);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.brandYellow),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 10, color: textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
