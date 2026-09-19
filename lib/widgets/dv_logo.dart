import 'package:flutter/material.dart';
import '../app/theme.dart';

/// DROPVOICE wordmark. Renders "DROP" in green, "VOICE" in white.
class DvLogo extends StatelessWidget {
  const DvLogo({super.key, this.size = 28, this.showTagline = false});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'DROP',
                style: Dv.display(size: size, color: Dv.green, weight: FontWeight.w900),
              ),
              TextSpan(
                text: 'VOICE',
                style: Dv.display(size: size, color: Dv.white, weight: FontWeight.w900),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text('YOUR SQUAD. YOUR COMMS.', style: Dv.mono(size: 10, color: Dv.slate)),
        ],
      ],
    );
  }
}
