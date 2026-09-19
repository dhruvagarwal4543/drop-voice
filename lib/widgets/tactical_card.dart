import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Dark graphite card with optional green left-edge accent line.
class TacticalCard extends StatelessWidget {
  const TacticalCard({
    super.key,
    required this.child,
    this.greenEdge = false,
    this.padding = const EdgeInsets.all(Dv.s16),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final bool greenEdge;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: color ?? Dv.graphite,
          borderRadius: BorderRadius.circular(Dv.r12),
          border: Border.all(color: borderColor ?? Dv.steel, width: 1),
          boxShadow: Dv.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dv.r12 - 1),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (greenEdge)
                  Container(
                    width: 3,
                    decoration: const BoxDecoration(
                      color: Dv.green,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Dv.r12),
                        bottomLeft: Radius.circular(Dv.r12),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
