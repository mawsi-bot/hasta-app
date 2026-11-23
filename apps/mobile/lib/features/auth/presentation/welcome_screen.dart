import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/build_config.dart';
import '../../../core/design/hasta_theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/hasta_button.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../test_mode/quick_test_panel.dart';
import '../domain/auth_controller.dart';
import '../domain/auth_state.dart';

/// Welcome (SPEC §5.2): ONE primary button, guest explainer + risk copy.
/// No Gmail/Google/Apple/phone button exists here (T20/T37 policy).
///
/// States: default · loading (signing in) · error (formula + hidden code) ·
/// offline (CTA disabled + banner + reason) · disabled (guest flag off) ·
/// cooldown (T42, remaining days).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const Key primaryButtonKey = Key('welcome-primary');
  static const Key logoKey = Key('welcome-logo');
  static const Key issueKey = Key('welcome-issue');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final HastaColors c = context.colors;
    final bool online = ref.isOnline;
    final AuthState auth = ref.watch(authControllerProvider);
    final bool busy = auth.phase == AuthPhase.signingIn;
    final WelcomeIssue? issue = auth.issue;
    final bool blocked = issue is GuestDisabledIssue || issue is CooldownIssue;
    final String locale = Localizations.localeOf(context).languageCode;

    final String? issueText = switch (issue) {
      null => null,
      CooldownIssue(:final int days) => l.welcomeCooldown(days),
      GuestDisabledIssue() => l.welcomeGuestDisabled,
      RateLimitedIssue() => l.welcomeRateLimited,
      FailureIssue(:final String code) => l.errorGeneric(code),
    };

    Widget logo = Semantics(
      label: l.appTitle,
      image: true,
      child: Container(
        key: logoKey,
        constraints: const BoxConstraints(minWidth: 88, minHeight: 88),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.bgBrandSubtle, borderRadius: BorderRadius.circular(HastaRadius.card)),
        padding: const EdgeInsets.all(HastaSpace.s16),
        child: Text('H', style: HastaType.display.copyWith(color: c.textLink, fontFamily: HastaType.latinFamily)),
      ),
    );
    // Compile-time guard: when false this branch (and the panel library code it
    // references) is tree-shaken out of the binary — verified by CI gate T36.
    if (BuildConfig.quickTestAccountsEnabled) {
      logo = RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: const Duration(seconds: 3)),
            (LongPressGestureRecognizer r) => r.onLongPress = () => showQuickTestPanel(context),
          ),
        },
        child: logo,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (!online) OfflineBanner(message: l.offlineBanner),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: HastaSpace.s24, vertical: HastaSpace.s32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: HastaSize.contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Center(child: logo),
                        const SizedBox(height: HastaSpace.s24),
                        Text(l.welcomeTitle,
                            textAlign: TextAlign.center, style: HastaType.display.copyWith(color: c.textPrimary)),
                        const SizedBox(height: HastaSpace.s12),
                        Text(l.welcomeGuestExplainer,
                            textAlign: TextAlign.center, style: HastaType.body.copyWith(color: c.textSecondary)),
                        const SizedBox(height: HastaSpace.s20),
                        _RiskCard(text: l.welcomeGuestRisk),
                        const SizedBox(height: HastaSpace.s32),
                        if (issueText != null) ...<Widget>[
                          Semantics(
                            liveRegion: true,
                            child: Row(
                              key: issueKey,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(Icons.error_outline, size: 20, color: c.textDanger),
                                const SizedBox(width: HastaSpace.s8),
                                Expanded(child: Text(issueText, style: HastaType.bodySm.copyWith(color: c.textDanger))),
                              ],
                            ),
                          ),
                          const SizedBox(height: HastaSpace.s12),
                        ],
                        HastaButton(
                          key: primaryButtonKey,
                          label: l.welcomePrimary,
                          loading: busy,
                          loadingLabel: l.loading,
                          onPressed: (!online || blocked)
                              ? null
                              : () => ref.read(authControllerProvider.notifier).continueAsGuest(locale: locale),
                        ),
                        if (!online) ...<Widget>[
                          const SizedBox(height: HastaSpace.s8),
                          Text(l.welcomeOfflineHint,
                              key: const Key('welcome-offline-hint'),
                              textAlign: TextAlign.center,
                              style: HastaType.caption.copyWith(color: c.textSecondary)),
                        ],
                        const SizedBox(height: HastaSpace.s16),
                        Text(l.welcomeConsent,
                            textAlign: TextAlign.center, style: HastaType.caption.copyWith(color: c.textSecondary)),
                        TextButton(
                          onPressed: () => _showLegal(context, l),
                          child: Text(l.welcomePrivacyTerms, style: HastaType.caption.copyWith(color: c.textLink)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegal(BuildContext context, AppLocalizations l) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(HastaSpace.s16, 0, HastaSpace.s16, HastaSpace.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l.welcomePrivacyTerms, style: HastaType.h2),
            const SizedBox(height: HastaSpace.s8),
            // Legal text is supplied by the legal owner before store submission.
            Text(l.comingSoon, style: HastaType.body),
          ],
        ),
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgSunken,
        borderRadius: BorderRadius.circular(HastaRadius.md),
        border: Border.all(color: c.borderSubtle),
      ),
      padding: const EdgeInsets.all(HastaSpace.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 20, color: c.stateWaiting),
          const SizedBox(width: HastaSpace.s8),
          Expanded(child: Text(text, key: const Key('welcome-risk'), style: HastaType.bodySm.copyWith(color: c.textPrimary))),
        ],
      ),
    );
  }
}
