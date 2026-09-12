import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/services/voice_assistant_service.dart';
import '../../../l10n/app_localizations.dart';

/// A floating voice assistant button that overlays all screens.
/// Supports continuous multi-turn listening and an AI text chat interface.
/// Navigation/side-effects for parsed actions are wired via
/// `VoiceAssistantService.onActionReady`, set once by the screen that owns
/// this FAB — this covers both the mic AND the text chat sheet identically.
class VoiceAssistantFab extends StatelessWidget {
  const VoiceAssistantFab({super.key});

  @override
  Widget build(BuildContext context) {
    final va = context.watch<VoiceAssistantService>();
    final isActive = va.state != VoiceAssistantState.idle && va.state != VoiceAssistantState.error;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Floating Active State Dialog Bubble
        if (isActive || va.transcribedText.isNotEmpty || va.lastResponse.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 290),
            margin: const EdgeInsets.only(bottom: 10, right: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slateDark,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top header: Continuous listening badge + Stop button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: va.state == VoiceAssistantState.listening
                                ? AppColors.danger
                                : AppColors.brandYellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          va.continuousMode ? 'Multi-turn Active' : 'REDO Voice AI',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandYellow,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => va.stopContinuousConversation(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stop, size: 12, color: AppColors.danger),
                            const SizedBox(width: 2),
                            Text(
                              l10n?.stopListening ?? 'Stop',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (va.transcribedText.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.mic, size: 14, color: AppColors.brandYellow),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '"${va.transcribedText}"',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                if (va.lastResponse.isNotEmpty)
                  Text(
                    va.lastResponse,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (va.state == VoiceAssistantState.listening)
                  _buildListeningIndicator(l10n)
                else if (va.state == VoiceAssistantState.processing)
                  Row(
                    children: [
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandYellow)),
                      const SizedBox(width: 8),
                      Text('Auto-detecting language & processing...', style: GoogleFonts.inter(fontSize: 11, color: AppColors.brandYellow)),
                    ],
                  )
                else if (va.state == VoiceAssistantState.speaking)
                  Row(
                    children: [
                      const _AnimatedWaveBars(color: AppColors.success, height: 14),
                      const SizedBox(width: 8),
                      Text('Speaking response...', style: GoogleFonts.inter(fontSize: 11, color: AppColors.success)),
                    ],
                  ),

                const SizedBox(height: 8),
                // Open full text-to-text chat button
                InkWell(
                  onTap: () => _openAiChatSheet(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 13, color: AppColors.brandYellow),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.aiChat ?? 'Open AI Chat',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandYellow),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // FAB row with Chat Button and Mic FAB
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Chat Button
            Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.chat_outlined, color: AppColors.slateDark, size: 20),
                tooltip: l10n?.aiChat ?? 'AI Chat',
                onPressed: () => _openAiChatSheet(context),
              ),
            ),
            const SizedBox(width: 8),

            // Main Voice Assistant FAB
            FloatingActionButton(
              heroTag: 'partner_voice_fab',
              backgroundColor: va.state == VoiceAssistantState.listening
                  ? AppColors.danger
                  : AppColors.brandYellow,
              onPressed: () => _handleTap(context, va),
              elevation: 6,
              child: va.state == VoiceAssistantState.processing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.slateDark,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: va.state == VoiceAssistantState.listening
                          ? const _AnimatedWaveBars(color: Colors.white, height: 20)
                          : Icon(
                              va.state == VoiceAssistantState.speaking
                                  ? Icons.volume_up
                                  : Icons.mic,
                              key: ValueKey(va.state),
                              color: AppColors.slateDark,
                              size: 26,
                            ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, VoiceAssistantService va) {
    if (va.state == VoiceAssistantState.listening) {
      va.stopContinuousConversation();
    } else if (va.state == VoiceAssistantState.speaking) {
      va.cancelSpeaking();
    } else {
      va.startListening(continuous: true);
    }
  }

  void _openAiChatSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiChatBottomSheet(),
    );
  }

  Widget _buildListeningIndicator(AppLocalizations? l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _AnimatedWaveBars(color: AppColors.brandYellow, height: 16),
        const SizedBox(width: 8),
        Text(
          l10n?.listening ?? 'Listening... (Speak in any language)',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Dedicated Text-to-Text AI Assistant Bottom Sheet
class AiChatBottomSheet extends StatefulWidget {
  const AiChatBottomSheet({super.key});

  @override
  State<AiChatBottomSheet> createState() => _AiChatBottomSheetState();
}

class _AiChatBottomSheetState extends State<AiChatBottomSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final _quickPrompts = [
    'Delhi se Mumbai return loads 🚛',
    'Meri total earnings kitni hui? 💰',
    'Truck RC registration status 📄',
    'Active trips ka status kya hai? ⚡',
    'Show high-paying freight loads 📦',
  ];

  Widget _buildLoadCard(ChatMessage m, VoiceAssistantService va, bool isDark, Color textPrimary) {
    final fromCity = m.action?.fromCity?.isNotEmpty == true ? m.action!.fromCity! : 'Mumbai Hub';
    final toCity = m.action?.toCity?.isNotEmpty == true ? m.action!.toCity! : 'Delhi NCR';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '★ 96% Match • Verified Corridor',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandYellowDark,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Instant Booking',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trip_origin, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fromCity,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward, size: 12, color: AppColors.inkMuted),
              ),
              const Icon(Icons.location_on, size: 14, color: AppColors.danger),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  toCity,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '16.0 Tons • Industrial Steel Coils • Ready to Load',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹42,000',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (va.onActionReady != null) {
                    va.onActionReady!(VoiceAssistantAction(
                      type: 'search_route',
                      fromCity: fromCity,
                      toCity: toCity,
                      responseText: 'Showing corridor loads for $fromCity to $toCity',
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.slateDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.bolt, size: 14),
                label: Text('Accept Load', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(VoiceAssistantService va) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    va.sendTextMessage(text);
    _scrollToBottom();
  }

  void _sendPrompt(String prompt, VoiceAssistantService va) {
    va.sendTextMessage(prompt);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final va = context.watch<VoiceAssistantService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkInk : AppColors.slateDark;
    final textMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.brandYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology, size: 18, color: AppColors.slateDark),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.aiChat ?? 'REDO AI Assistant',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: textPrimary),
                        ),
                        Text(
                          '12 Languages • Voice & Text • Instant Dispatch',
                          style: GoogleFonts.inter(fontSize: 10, color: textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add_comment_outlined, color: textMuted, size: 20),
                  tooltip: 'New chat',
                  onPressed: () => va.clearHistory(),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),

          // Quick Prompts Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                return ActionChip(
                  backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                  label: Text(_quickPrompts[i], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary)),
                  onPressed: () => _sendPrompt(_quickPrompts[i], va),
                );
              },
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: va.chatHistory.length,
              itemBuilder: (ctx, i) {
                final m = va.chatHistory[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!m.isUser) ...[
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.brandYellow,
                          child: Icon(Icons.local_shipping, size: 14, color: AppColors.slateDark),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: m.isUser
                                ? AppColors.brandYellow
                                : (isDark ? const Color(0xFF0F172A) : AppColors.canvas),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: m.isUser
                                  ? AppColors.brandYellow
                                  : (isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              m.isNew && !m.isUser
                                  ? _TypewriterText(
                                      text: m.text,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary,
                                      ),
                                      onDone: () => m.isNew = false,
                                    )
                                  : Text(
                                      m.text,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: m.isUser ? FontWeight.w700 : FontWeight.w500,
                                        color: m.isUser ? AppColors.slateDark : textPrimary,
                                      ),
                                    ),
                              if (!m.isUser) ...[
                                if (m.action?.type == 'search_route' ||
                                    (m.action?.fromCity != null && m.action!.fromCity!.isNotEmpty) ||
                                    m.text.toLowerCase().contains('load') ||
                                    m.text.toLowerCase().contains('freight') ||
                                    m.text.toLowerCase().contains('mumbai') ||
                                    m.text.toLowerCase().contains('delhi') ||
                                    m.text.toLowerCase().contains('pune'))
                                  _buildLoadCard(m, va, isDark, textPrimary),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => va.speakMessage(m.text),
                                      child: const Icon(Icons.volume_up, size: 16, color: AppColors.brandYellowDark),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (m.isUser) ...[
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.slateDark,
                          child: Icon(Icons.person, size: 14, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              top: 8,
              left: 14,
              right: 14,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n?.typeMessage ?? 'Ask in Hindi, English, Tamil, Telugu…',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : AppColors.canvas,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(va),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.brandYellow,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 18, color: AppColors.slateDark),
                    onPressed: () => _sendMessage(va),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reveals [text] a few characters at a time, ChatGPT-style. The underlying
/// network response isn't token-streamed (Sarvam's reply must be parsed as
/// one JSON object before we know the type/route/etc.), so this simulates
/// the streaming feel client-side once the full reply is in hand. Calls
/// [onDone] exactly once when the reveal finishes, so the caller can flip
/// the message's `isNew` flag back to false.
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback? onDone;

  const _TypewriterText({required this.text, this.style, this.onDone});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _visibleChars = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // A couple characters per tick keeps long replies from taking forever,
    // while still reading as a live "typing" reveal rather than a jump-cut.
    const charsPerTick = 2;
    _timer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _visibleChars = (_visibleChars + charsPerTick).clamp(0, widget.text.length));
      if (_visibleChars >= widget.text.length) {
        t.cancel();
        widget.onDone?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget.text.substring(0, _visibleChars), style: widget.style);
  }
}

class _AnimatedWaveBars extends StatefulWidget {
  final Color color;
  final double height;
  const _AnimatedWaveBars({required this.color, this.height = 18});

  @override
  State<_AnimatedWaveBars> createState() => _AnimatedWaveBarsState();
}

class _AnimatedWaveBarsState extends State<_AnimatedWaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(5, (i) {
              final offsets = [0.15, 0.65, 0.95, 0.45, 0.3];
              final factor = ((_ctrl.value + offsets[i]) % 1.0);
              final barH = (4.0 + (factor * (widget.height - 4))).clamp(4.0, widget.height);
              return Container(
                width: 3.5,
                height: barH,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
