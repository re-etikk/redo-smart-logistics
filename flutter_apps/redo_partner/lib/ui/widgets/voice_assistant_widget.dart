import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/services/voice_assistant_service.dart';

/// A floating voice assistant button that overlays all screens.
/// Tap to start/stop listening. Shows animated mic and transcript.
class VoiceAssistantFab extends StatelessWidget {
  final Function(VoiceAssistantAction)? onAction;
  const VoiceAssistantFab({super.key, this.onAction});

  @override
  Widget build(BuildContext context) {
    final va = context.watch<VoiceAssistantService>();
    final isActive = va.state != VoiceAssistantState.idle && va.state != VoiceAssistantState.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isActive || va.transcribedText.isNotEmpty || va.lastResponse.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            margin: const EdgeInsets.only(bottom: 10, right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.slateDark,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (va.transcribedText.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.mic, size: 12, color: AppColors.brandYellow),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          va.transcribedText,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                  _buildListeningIndicator()
                else if (va.state == VoiceAssistantState.processing)
                  Text('Thinking...', style: GoogleFonts.inter(fontSize: 12, color: AppColors.brandYellow))
                else if (va.state == VoiceAssistantState.speaking)
                  Text('Speaking...', style: GoogleFonts.inter(fontSize: 12, color: AppColors.success)),
              ],
            ),
          ),
        FloatingActionButton(
          heroTag: 'voice_assistant_fab',
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
                  child: Icon(
                    va.state == VoiceAssistantState.listening
                        ? Icons.mic_off
                        : va.state == VoiceAssistantState.speaking
                            ? Icons.volume_up
                            : Icons.mic,
                    key: ValueKey(va.state),
                    color: AppColors.slateDark,
                    size: 26,
                  ),
                ),
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, VoiceAssistantService va) {
    if (va.state == VoiceAssistantState.listening) {
      va.stopListening();
    } else if (va.state == VoiceAssistantState.speaking) {
      va.cancelSpeaking();
    } else {
      va.startListening().then((_) {
        if (va.lastAction != null && onAction != null) {
          onAction!(va.lastAction!);
        }
      });
    }
  }

  Widget _buildListeningIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.graphic_eq, color: AppColors.brandYellow, size: 16),
        const SizedBox(width: 6),
        Text(
          'Listening...',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.brandYellow,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
