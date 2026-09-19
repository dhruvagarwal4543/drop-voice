import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';

/// Primary full-width green CTA button with press scale animation.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = const Size(double.infinity, 52),
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Size size;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed == null || widget.isLoading) return;
    _ctrl.reverse();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) => _ctrl.forward();
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: (widget.onPressed == null || widget.isLoading) ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size.width,
          height: widget.size.height,
          decoration: BoxDecoration(
            color: (widget.onPressed == null || widget.isLoading)
                ? Dv.green.withValues(alpha: 0.4)
                : Dv.green,
            borderRadius: BorderRadius.circular(Dv.r8),
            boxShadow: widget.onPressed != null && !widget.isLoading
                ? Dv.greenGlow
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.black, size: 18),
                        const SizedBox(width: Dv.s8),
                      ],
                      Text(widget.label, style: Dv.button()),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary button.
class SecondaryButton extends StatefulWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = const Size(double.infinity, 52),
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Size size;

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.reverse();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          width: widget.size.width,
          height: widget.size.height,
          decoration: BoxDecoration(
            color: Dv.graphite,
            borderRadius: BorderRadius.circular(Dv.r8),
            border: Border.all(color: Dv.steel, width: 1),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Dv.ash, size: 18),
                  const SizedBox(width: Dv.s8),
                ],
                Text(widget.label, style: Dv.button(color: Dv.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Red destructive button (Leave room, disconnect).
class DangerButton extends StatefulWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = const Size(double.infinity, 52),
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Size size;

  @override
  State<DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<DangerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.reverse();
        HapticFeedback.heavyImpact();
      },
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          width: widget.size.width,
          height: widget.size.height,
          decoration: BoxDecoration(
            color: Dv.crimsonDim,
            borderRadius: BorderRadius.circular(Dv.r8),
            border: Border.all(color: Dv.crimson.withValues(alpha: 0.5), width: 1),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Dv.crimson, size: 18),
                  const SizedBox(width: Dv.s8),
                ],
                Text(widget.label, style: Dv.button(color: Dv.crimson)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular icon button for room controls (mic, audio, etc.)
class ControlButton extends StatefulWidget {
  const ControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isActive = true,
    this.activeColor = Dv.charcoal,
    this.inactiveColor = Dv.crimsonDim,
    this.iconColor = Dv.white,
    this.inactiveIconColor = Dv.crimson,
    this.size = 56,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Color iconColor;
  final Color inactiveIconColor;
  final double size;
  final String? tooltip;

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isActive ? widget.activeColor : widget.inactiveColor;
    final ic = widget.isActive ? widget.iconColor : widget.inactiveIconColor;

    final button = GestureDetector(
      onTapDown: (_) {
        _ctrl.reverse();
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _ctrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: Dv.steel, width: 1),
          ),
          child: Icon(widget.icon, color: ic, size: widget.size * 0.42),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
