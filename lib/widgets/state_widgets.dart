import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Tactical loading spinner with label.
class DvLoadingState extends StatelessWidget {
  const DvLoadingState({super.key, this.message = 'Loading...'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Dv.green),
            ),
          ),
          const SizedBox(height: Dv.s16),
          Text(message.toUpperCase(), style: Dv.mono(size: 11, color: Dv.ash)),
        ],
      ),
    );
  }
}

/// Tactical empty state with icon, headline, subtext.
class DvEmptyState extends StatelessWidget {
  const DvEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dv.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Dv.graphite,
                borderRadius: BorderRadius.circular(Dv.r16),
                border: Border.all(color: Dv.steel),
              ),
              child: Icon(icon, color: Dv.slate, size: 32),
            ),
            const SizedBox(height: Dv.s20),
            Text(title, style: Dv.title(size: 16, color: Dv.white), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: Dv.s8),
              Text(subtitle!, style: Dv.body(size: 14), textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: Dv.s24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Tactical error state with red icon, message, retry button.
class DvErrorState extends StatelessWidget {
  const DvErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.onBack,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dv.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Dv.crimsonDim,
                borderRadius: BorderRadius.circular(Dv.r16),
                border: Border.all(color: Dv.crimson.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.warning_rounded, color: Dv.crimson, size: 32),
            ),
            const SizedBox(height: Dv.s20),
            Text(
              message,
              style: Dv.body(color: Dv.ash),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Dv.s24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('RETRY'),
                ),
              ),
            ],
            if (onBack != null) ...[
              const SizedBox(height: Dv.s12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('GO BACK'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
