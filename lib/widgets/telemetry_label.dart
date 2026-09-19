import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Monospace uppercase telemetry label.
/// e.g. "LATENCY · 42ms", "CONNECTED", "3 PARTICIPANTS"
class TelemetryLabel extends StatelessWidget {
  const TelemetryLabel({
    super.key,
    required this.text,
    this.color = Dv.ash,
    this.size = 11,
    this.dotColor,
  });

  final String text;
  final Color color;
  final double size;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dotColor != null) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
        ],
        Text(
          text.toUpperCase(),
          style: Dv.mono(size: size, color: color),
        ),
      ],
    );
  }
}

/// Status badge pill — CONNECTED / RECONNECTING / DISCONNECTED
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dv.s8, vertical: Dv.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dv.r100),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label.toUpperCase(), style: Dv.mono(size: 10, color: color)),
        ],
      ),
    );
  }
}
