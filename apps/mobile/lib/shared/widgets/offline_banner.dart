import 'package:flutter/material.dart';

import '../../core/design/hasta_theme.dart';
import '../../core/design/tokens.dart';

/// DS OfflineBanner — icon + text (never colour alone).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('offline-banner'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: HastaSize.touchTargetIos),
        color: c.bgSunken,
        padding: const EdgeInsets.symmetric(horizontal: HastaSpace.screenHorizontalPadding, vertical: HastaSpace.s8),
        child: Row(
          children: <Widget>[
            Icon(Icons.cloud_off_outlined, size: 20, color: c.stateWaiting),
            const SizedBox(width: HastaSpace.s8),
            Expanded(
              child: Text(message, style: HastaType.caption.copyWith(color: c.textPrimary), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
