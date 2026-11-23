import 'package:flutter/material.dart';

import '../../core/design/hasta_theme.dart';
import '../../core/design/tokens.dart';
import 'hasta_button.dart';

/// DS EmptyState.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HastaSpace.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: HastaSize.contentMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 48, color: c.textTertiary),
              const SizedBox(height: HastaSpace.s16),
              Text(title, textAlign: TextAlign.center, style: HastaType.subtitle.copyWith(color: c.textPrimary)),
              if (body != null) ...<Widget>[
                const SizedBox(height: HastaSpace.s8),
                Text(body!, textAlign: TextAlign.center, style: HastaType.bodySm.copyWith(color: c.textSecondary)),
              ],
              if (actionLabel != null) ...<Widget>[
                const SizedBox(height: HastaSpace.s16),
                HastaButton(label: actionLabel!, onPressed: onAction, variant: HastaButtonVariant.secondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// DS ErrorState — follows the error formula (what happened + what to do + hidden code).
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.retryLabel, required this.onRetry});

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HastaSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 40, color: c.textDanger),
            const SizedBox(height: HastaSpace.s12),
            Text(message, key: const Key('error-message'), textAlign: TextAlign.center, style: HastaType.body.copyWith(color: c.textPrimary)),
            const SizedBox(height: HastaSpace.s16),
            HastaButton(label: retryLabel, onPressed: onRetry, variant: HastaButtonVariant.secondary, icon: Icons.refresh),
          ],
        ),
      ),
    );
  }
}

/// DS Skeleton list (max rows from performance budget).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 3, required this.semanticLabel});

  final int rows;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    final int n = rows.clamp(1, HastaSize.skeletonRowsMax);
    return Semantics(
      label: semanticLabel,
      child: ListView.separated(
        key: const Key('skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(HastaSpace.screenHorizontalPadding),
        itemCount: n,
        separatorBuilder: (_, __) => const SizedBox(height: HastaSpace.s12),
        itemBuilder: (_, int i) => Container(
          height: HastaSize.buttonLg,
          decoration: BoxDecoration(color: c.bgSunken, borderRadius: BorderRadius.circular(HastaRadius.sm)),
        ),
      ),
    );
  }
}
