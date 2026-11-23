import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/hasta_theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/hasta_button.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/google_auth_launcher.dart';
import '../data/identity_repository.dart';

Future<void> showLinkedAccountsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const LinkedAccountsSheet(),
    );

enum _Phase { loading, ready, linking, error }

/// Settings → Account → Linked accounts (SPEC 1.0.2 §5.4, DS stateMatrix `linkedAccountsGmail`).
/// States: loading (spinner), empty (not linked + Connect), error (formula + Retry = fresh link:start),
/// offline (Connect disabled with reason, T43), permissionDenied (cancel notice), plus linked / unlink blocked.
/// Height grows with content (min-height only) so 200 % Myanmar text never clips.
class LinkedAccountsSheet extends ConsumerStatefulWidget {
  const LinkedAccountsSheet({super.key});

  static const Key connectKey = Key('gmail-connect');
  static const Key unlinkKey = Key('gmail-unlink');
  static const Key retryKey = Key('gmail-retry');
  static const Key cancelledKey = Key('gmail-cancelled');

  @override
  ConsumerState<LinkedAccountsSheet> createState() => _LinkedAccountsSheetState();
}

class _LinkedAccountsSheetState extends ConsumerState<LinkedAccountsSheet> {
  _Phase _phase = _Phase.loading;
  GoogleLink? _link;
  ApiFailure? _failure;
  bool _cancelled = false;
  bool _unlinkBlocked = false;
  VoidCallback _retry = () {};

  IdentityRepository get _repo => ref.read(identityRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _fail(ApiFailure f, VoidCallback retry) {
    if (!mounted) return;
    setState(() {
      _failure = f;
      _retry = retry;
      _phase = _Phase.error;
    });
  }

  void _ready({GoogleLink? link, bool cancelled = false}) {
    if (!mounted) return;
    setState(() {
      _link = link;
      _cancelled = cancelled;
      _unlinkBlocked = false;
      _phase = _Phase.ready;
    });
  }

  Future<void> _load() async {
    try {
      _ready(link: await _repo.current());
    } on ApiFailure catch (f) {
      _fail(f, _reload);
    }
  }

  void _reload() {
    setState(() => _phase = _Phase.loading);
    _load();
  }

  Future<void> _connect() async {
    if (_phase == _Phase.linking || !(ref.read(onlineProvider).valueOrNull ?? true)) return;
    setState(() {
      _phase = _Phase.linking;
      _cancelled = false;
    });
    try {
      _ready(link: await _repo.link());
    } on AuthCancelled {
      _ready(cancelled: true);
    } on ApiFailure catch (f) {
      _fail(f, _connect);
    }
  }

  Future<void> _unlink() async {
    try {
      await _repo.unlink();
      _ready();
    } on ApiFailure catch (f) {
      if (f.code != 'recovery_required') return _fail(f, _unlink);
      if (mounted) setState(() => _unlinkBlocked = true);
    }
  }

  String _errorCopy(AppLocalizations l, ApiFailure f) => switch (f.code) {
        'identity_in_use' => l.gmailIdentityInUse,
        'google_email_unverified' => l.gmailEmailUnverified,
        _ => l.gmailLinkFailed(f.displayCode),
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final HastaColors c = context.colors;
    final bool online = ref.isOnline;
    TextStyle body(Color color) => HastaType.body.copyWith(color: color);
    final List<Widget> children = switch (_phase) {
      _Phase.loading => <Widget>[Center(child: CircularProgressIndicator(semanticsLabel: l.loading))],
      _Phase.error => <Widget>[
          ErrorState(key: LinkedAccountsSheet.retryKey, message: _errorCopy(l, _failure!), retryLabel: l.retry, onRetry: _retry),
        ],
      _ when _link != null => <Widget>[
          Text(l.gmailLinkedMasked(_link!.emailMasked ?? ''), style: body(c.textPrimary)),
          if (_unlinkBlocked) Text(l.gmailUnlinkBlocked, style: body(c.textDanger)),
          HastaButton(key: LinkedAccountsSheet.unlinkKey, label: l.gmailUnlink, variant: HastaButtonVariant.secondary,
              onPressed: online ? _unlink : null),
        ],
      _ => <Widget>[
          Text(l.gmailNotLinked, style: body(c.textPrimary)),
          Text(l.gmailBenefit, style: body(c.textSecondary)),
          Text(l.welcomeGuestRisk, style: body(c.textSecondary)),
          if (_cancelled) Text(l.gmailLinkCancelled, key: LinkedAccountsSheet.cancelledKey, style: body(c.textSecondary)),
          if (!online) Text(l.settingsOnlineOnly, style: body(c.textTertiary)),
          HastaButton(key: LinkedAccountsSheet.connectKey, label: l.settingsConnectGmail, loading: _phase == _Phase.linking,
              onPressed: online ? _connect : null),
        ],
    };
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HastaSpace.screenHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l.settingsLinkedAccounts, style: HastaType.subtitle.copyWith(color: c.textPrimary)),
            for (final Widget w in children) ...<Widget>[const SizedBox(height: HastaSpace.s12), w],
          ],
        ),
      ),
    );
  }
}
