import 'package:flutter/material.dart';

import '../../core/design/hasta_theme.dart';
import '../../core/design/tokens.dart';

/// DS ListItem. Disabled rows stay visible and announce the reason (T43).
class HastaListRow extends StatelessWidget {
  const HastaListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    final Color titleColor = !enabled ? c.textTertiary : (destructive ? c.textDanger : c.textPrimary);
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: HastaSize.touchTargetAndroid + HastaSpace.s8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: HastaSpace.cardInnerPaddingSettings, vertical: HastaSpace.listRowVerticalPadding),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 24, color: !enabled ? c.textTertiary : (destructive ? c.textDanger : c.iconPrimary)),
                  const SizedBox(width: HastaSpace.avatarToText),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: HastaType.body.copyWith(color: titleColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: HastaType.caption.copyWith(color: c.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (trailing == null && onTap != null && enabled) Icon(Icons.chevron_right, color: c.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// DS SectionHeader (overline style, never uppercase).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          HastaSpace.screenHorizontalPadding, HastaSpace.sectionGap, HastaSpace.screenHorizontalPadding, HastaSpace.s8),
      child: Semantics(header: true, child: Text(label, style: HastaType.overline.copyWith(color: c.textSecondary))),
    );
  }
}
