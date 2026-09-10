import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/voice_assistant_service.dart';
import '../../core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class VoiceAssistantFab extends StatefulWidget {
  final Function(VoiceAssistantAction) onAction;

  const VoiceAssistantFab({super.key, required this.onAction});

  @override
  State<VoiceAssistantFab> createState() => _VoiceAssistantFabState();
}

class _VoiceAssistantFabState extends State<VoiceAssistantFab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<VoiceAssistantService>().init());
  }

  void _showListeningDialog(BuildContext context) {
    final service = context.read<VoiceAssistantService>();
    service.startListening((action) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      widget.onAction(action);
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer<VoiceAssistantService>(
        builder: (context, va, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (va.isProcessing)
                  const CircularProgressIndicator(color: AppColors.brandYellow)
                else
                  Icon(
                    Icons.mic,
                    size: 64,
                    color: va.isListening ? AppColors.brandYellow : AppColors.inkMuted,
                  ),
                const SizedBox(height: 24),
                Text(
                  va.isProcessing 
                      ? 'Processing...' 
                      : (va.isListening ? 'Listening...' : 'Tap to speak'),
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (va.currentText.isNotEmpty)
                  Text(
                    va.currentText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (!va.isListening && !va.isProcessing)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      if (service.isListening) {
        // Handle unexpected dismissals
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showListeningDialog(context),
      backgroundColor: AppColors.brandYellow,
      child: const Icon(Icons.mic, color: AppColors.slateDark),
    );
  }
}
