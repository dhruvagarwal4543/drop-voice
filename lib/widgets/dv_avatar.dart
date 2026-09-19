import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Speaking ring — animates around a participant avatar when they're talking.
/// Driven by real LiveKit isSpeaking state. No simulation.
class SpeakingRing extends StatefulWidget {
  const SpeakingRing({
    super.key,
    required this.child,
    required this.isSpeaking,
    this.ringSize = 8,
  });

  final Widget child;
  final bool isSpeaking;
  final double ringSize;

  @override
  State<SpeakingRing> createState() => _SpeakingRingState();
}

class _SpeakingRingState extends State<SpeakingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    if (widget.isSpeaking) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(SpeakingRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isSpeaking && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isSpeaking)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _opacity.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Dv.green,
                        width: 2.5,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}

/// Small presence dot — green (online), amber (in game), grey (offline).
class PresenceDot extends StatelessWidget {
  const PresenceDot({
    super.key,
    this.isOnline = true,
    this.size = 10,
  });

  final bool isOnline;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? Dv.green : Dv.slate,
        shape: BoxShape.circle,
        border: Border.all(color: Dv.obsidian, width: 2),
      ),
    );
  }
}

/// Circular avatar with initials, speaking ring and presence dot.
class DvAvatar extends StatelessWidget {
  const DvAvatar({
    super.key,
    required this.name,
    this.radius = 32,
    this.isSpeaking = false,
    this.isMuted = false,
    this.showPresence = false,
    this.isOnline = true,
    this.imageUrl,
  });

  final String name;
  final double radius;
  final bool isSpeaking;
  final bool isMuted;
  final bool showPresence;
  final bool isOnline;
  final String? imageUrl;

  Color _avatarColor() {
    final colors = [
      const Color(0xFF1B5E20),
      const Color(0xFF0D47A1),
      const Color(0xFF4A148C),
      const Color(0xFF1A237E),
      const Color(0xFF006064),
      const Color(0xFF37474F),
    ];
    final hash = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[hash];
  }

  String get _initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _avatarColor(),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSpeaking ? Dv.green : Dv.steel,
          width: isSpeaking ? 2 : 1,
        ),
        image: imageUrl != null && imageUrl!.isNotEmpty
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? null
          : Center(
              child: Text(
                _initials,
                style: Dv.title(size: radius * 0.65, color: Dv.white, weight: FontWeight.w700),
              ),
            ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SpeakingRing(
          isSpeaking: isSpeaking,
          child: avatar,
        ),
        if (isMuted)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: Dv.charcoal,
                shape: BoxShape.circle,
                border: Border.all(color: Dv.steel),
              ),
              child: Icon(
                Icons.mic_off,
                size: radius * 0.35,
                color: Dv.slate,
              ),
            ),
          ),
        if (showPresence && !isMuted)
          Positioned(
            bottom: 0,
            right: 0,
            child: PresenceDot(isOnline: isOnline, size: radius * 0.45),
          ),
      ],
    );
  }
}
