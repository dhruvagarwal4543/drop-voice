import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'dv_avatar.dart';

/// Full participant tile showing avatar, name, speaking + mute state.
/// Driven entirely by real LiveKit events — no mock state.
class ParticipantCard extends StatelessWidget {
  const ParticipantCard({
    super.key,
    required this.name,
    required this.isLocal,
    required this.isSpeaking,
    required this.isMuted,
  });

  final String name;
  final bool isLocal;
  final bool isSpeaking;
  final bool isMuted;

  String get _displayName => isLocal ? '$name (You)' : name;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: Dv.s8),
      padding: EdgeInsets.symmetric(horizontal: Dv.s12, vertical: Dv.s8),
      decoration: BoxDecoration(
        color: isSpeaking ? Dv.green.withValues(alpha: 0.06) : Dv.graphite,
        borderRadius: BorderRadius.circular(Dv.r12),
        border: Border.all(
          color: isSpeaking ? Dv.green.withValues(alpha: 0.4) : Dv.steel,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          DvAvatar(
            name: name,
            radius: 20,
            isSpeaking: isSpeaking,
            isMuted: isMuted,
          ),
          const SizedBox(width: Dv.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: Dv.body(color: Dv.white, weight: FontWeight.w600, size: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (isSpeaking)
                  Text('SPEAKING', style: Dv.mono(size: 10, color: Dv.green))
                else if (isMuted)
                  Text('MUTED', style: Dv.mono(size: 10, color: Dv.slate))
                else
                  Text('LISTENING', style: Dv.mono(size: 10, color: Dv.slate)),
              ],
            ),
          ),
          // Mic icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isMuted
                ? const Icon(Icons.mic_off_rounded, size: 18, color: Dv.slate, key: ValueKey('off'))
                : Icon(
                    Icons.mic_rounded,
                    size: 18,
                    color: isSpeaking ? Dv.green : Dv.ash,
                    key: const ValueKey('on'),
                  ),
          ),
        ],
      ),
    );
  }
}
