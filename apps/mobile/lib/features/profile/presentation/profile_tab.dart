import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/drift/app_database.dart';
import '../../../core/design/hasta_theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/api_failure.dart';
import '../../../shared/widgets/hasta_button.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/domain/auth_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_providers.dart';

/// Own profile (SPEC §10.1 basics). Reads Drift; `/v1/me` refresh runs in the
/// background. States: loading (skeleton) · error (retry, only when no cache) ·
/// offline (cached + shell banner) · content.
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AsyncValue<LocalProfile?> profile = ref.watch(myProfileProvider);
    final AsyncValue<void> refresh = ref.watch(profileRefreshProvider);
    final bool isGuest = ref.watch(authControllerProvider.select((s) => s.account?.isGuest ?? true));

    final LocalProfile? p = profile.valueOrNull;
    if (p == null) {
      if (refresh.hasError) {
        final Object e = refresh.error!;
        return ErrorState(
          message: l.errorGeneric(e is ApiFailure ? e.displayCode : 'E-APP'),
          retryLabel: l.retry,
          onRetry: () => ref.invalidate(profileRefreshProvider),
        );
      }
      return SkeletonList(rows: 4, semanticLabel: l.loading);
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(profileRefreshProvider.future),
      child: _ProfileBody(profile: p, isGuest: isGuest),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile, required this.isGuest});
  final LocalProfile profile;
  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final HastaColors c = context.colors;
    final int pending = ref.watch(profilePendingProvider).valueOrNull ?? 0;
    final String? syncError = ref.watch(profileSyncErrorProvider).valueOrNull;
    final String name = (profile.displayName?.isNotEmpty ?? false) ? profile.displayName! : l.profileNoName;

    return ListView(
      padding: const EdgeInsets.all(HastaSpace.screenHorizontalPadding),
      children: <Widget>[
        Row(
          children: <Widget>[
            const Spacer(),
            IconButton(
              key: const Key('open-settings'),
              tooltip: l.settingsTitle,
              icon: Icon(Icons.settings_outlined, color: c.iconPrimary),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: c.bgBrandSubtle,
            child: Icon(Icons.person, size: 48, color: c.textLink),
          ),
        ),
        const SizedBox(height: HastaSpace.s12),
        Text(name,
            key: const Key('profile-name'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: HastaType.h1.copyWith(color: c.textPrimary)),
        if (profile.username != null)
          Text('@${profile.username}',
              textAlign: TextAlign.center, style: HastaType.bodySm.copyWith(color: c.textSecondary)),
        const SizedBox(height: HastaSpace.s8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: HastaSpace.s8,
          runSpacing: HastaSpace.s8,
          children: <Widget>[
            if (isGuest) _Chip(icon: Icons.person_outline, label: l.profileGuestBadge, color: c.textSecondary),
            if (pending > 0)
              _Chip(key: const Key('profile-pending'), icon: Icons.schedule, label: l.profileSyncPending, color: c.stateWaiting),
          ],
        ),
        if (syncError == 'username_taken') ...<Widget>[
          const SizedBox(height: HastaSpace.s8),
          Text(l.profileUsernameTaken,
              key: const Key('profile-sync-error'),
              textAlign: TextAlign.center,
              style: HastaType.bodySm.copyWith(color: c.textDanger)),
        ],
        if (profile.bio?.isNotEmpty ?? false) ...<Widget>[
          const SizedBox(height: HastaSpace.s16),
          Text(profile.bio!, style: HastaType.body.copyWith(color: c.textPrimary)),
        ],
        const SizedBox(height: HastaSpace.s24),
        HastaButton(
          key: const Key('edit-profile'),
          label: l.profileEdit,
          variant: HastaButtonVariant.secondary,
          icon: Icons.edit_outlined,
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => EditProfileScreen(initial: profile))),
        ),
        if (isGuest) ...<Widget>[
          const SizedBox(height: HastaSpace.s16),
          Container(
            padding: const EdgeInsets.all(HastaSpace.cardInnerPaddingSettings),
            decoration: BoxDecoration(color: c.bgBrandSubtle, borderRadius: BorderRadius.circular(HastaRadius.card)),
            child: Row(
              children: <Widget>[
                Icon(Icons.shield_outlined, color: c.textLink),
                const SizedBox(width: HastaSpace.s12),
                Expanded(child: Text(l.profileGmailNudge, style: HastaType.bodySm.copyWith(color: c.textPrimary))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HastaSpace.s12, vertical: HastaSpace.s4),
      decoration: BoxDecoration(
        color: c.bgSunken,
        borderRadius: BorderRadius.circular(HastaRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: HastaSpace.s4),
          Flexible(child: Text(label, style: HastaType.caption.copyWith(color: c.textPrimary), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
