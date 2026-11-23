import 'package:flutter/material.dart';

import '../../core/design/hasta_theme.dart';
import '../../core/design/tokens.dart';

enum HastaButtonVariant { primary, secondary, ghost, danger }

/// DS Button: variants primary/secondary/ghost/danger; states default, pressed,
/// disabled (onPressed == null), loading, focus. Min-height only (Myanmar rule).
class HastaButton extends StatelessWidget {
  const HastaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = HastaButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final HastaButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    final bool enabled = onPressed != null && !loading;
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      HastaButtonVariant.primary => (c.actionPrimary, c.textOnBrand, BorderSide.none),
      HastaButtonVariant.secondary => (c.bgSurface, c.textLink, BorderSide(color: c.borderStrong)),
      HastaButtonVariant.ghost => (c.bgSurface.withAlpha(0), c.textLink, BorderSide.none),
      HastaButtonVariant.danger => (c.textDanger, c.textOnBrand, BorderSide.none),
    };
    final Color disabledBg = variant == HastaButtonVariant.ghost ? bg : c.bgSunken;

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? (loadingLabel ?? label) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: HastaSize.buttonLg, minWidth: HastaSize.touchTargetAndroid),
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
                (Set<WidgetState> s) => s.contains(WidgetState.disabled) && !loading ? disabledBg : bg),
            foregroundColor: WidgetStateProperty.resolveWith(
                (Set<WidgetState> s) => s.contains(WidgetState.disabled) && !loading ? c.textTertiary : fg),
            overlayColor: WidgetStatePropertyAll<Color>(fg.withAlpha(24)),
            side: WidgetStatePropertyAll<BorderSide>(side),
            minimumSize: const WidgetStatePropertyAll<Size>(Size(HastaSize.touchTargetAndroid, HastaSize.buttonLg)),
            padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: HastaSpace.s20, vertical: HastaSpace.s12)),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(HastaRadius.md))),
            textStyle: const WidgetStatePropertyAll<TextStyle>(HastaType.bodyStrong),
          ),
          child: loading
              ? SizedBox.square(
                  dimension: HastaSpace.s20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[Icon(icon, size: 20), const SizedBox(width: HastaSpace.s8)],
                    Flexible(child: Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
      ),
    );
  }
}
