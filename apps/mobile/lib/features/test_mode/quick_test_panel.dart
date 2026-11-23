import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/hasta_theme.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_failure.dart';
import '../../core/providers.dart';
import '../../shared/widgets/list_row.dart';
import '../../shared/widgets/state_views.dart';
import '../auth/domain/auth_controller.dart';

/// Marker checked by CI gate T36: it must NOT appear in release/production
/// artefacts. Only referenced from code guarded by
/// `BuildConfig.quickTestAccountsEnabled` (a compile-time constant).
const String kQuickTestPanelMarker = 'hasta-qa-quick-test-panel';

/// QA-only — opened by a 3 s long-press on the Welcome logo in dev/test/beta
/// builds (SPEC §19). Copy is intentionally English and not localised: this
/// surface never ships to users.
Future<void> showQuickTestPanel(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const QuickTestPanel(),
    );

final AutoDisposeFutureProvider<List<Map<String, dynamic>>> _testAccountsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> ref) async {
  final Map<String, dynamic>? r = await ref.read(apiClientProvider).get('/v1/test/accounts', auth: false);
  return (r?['accounts'] as List<dynamic>? ?? <dynamic>[]).cast<Map<String, dynamic>>();
});

class QuickTestPanel extends ConsumerStatefulWidget {
  const QuickTestPanel({super.key});

  @override
  ConsumerState<QuickTestPanel> createState() => _QuickTestPanelState();
}

class _QuickTestPanelState extends ConsumerState<QuickTestPanel> {
  String? _busy;
  String? _error;

  Future<void> _signIn(String handle) async {
    setState(() {
      _busy = handle;
      _error = null;
    });
    try {
      final String dt = await ref.read(authRepositoryProvider).ensureDeviceToken();
      final Map<String, dynamic>? r = await ref
          .read(apiClientProvider)
          .post('/v1/test/accounts/$handle/session', body: <String, String>{'device_token': dt});
      await ref.read(authControllerProvider.notifier).adoptSession(r!);
      if (mounted) Navigator.of(context).pop();
    } on ApiFailure catch (f) {
      setState(() => _error = 'Sign-in failed (${f.displayCode})');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _reset(String handle) async {
    try {
      await ref.read(apiClientProvider).post('/v1/test/accounts/$handle/reset');
      ref.invalidate(_testAccountsProvider);
    } on ApiFailure catch (f) {
      setState(() => _error = 'Reset failed (${f.displayCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final HastaColors c = context.colors;
    final bool online = ref.isOnline;
    final AsyncValue<List<Map<String, dynamic>>> accounts = ref.watch(_testAccountsProvider);
    return Semantics(
      label: kQuickTestPanelMarker,
      child: SafeArea(
        key: const Key(kQuickTestPanelMarker),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: HastaSpace.s16),
                child: Text('Quick test accounts', style: HastaType.h2.copyWith(color: c.textPrimary)),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(HastaSpace.s16),
                  child: Text(_error!, style: HastaType.bodySm.copyWith(color: c.textDanger)),
                ),
              Expanded(
                child: !online
                    ? const EmptyState(icon: Icons.cloud_off_outlined, title: 'Offline — test accounts need the network')
                    : accounts.when(
                        loading: () => const SkeletonList(rows: 6, semanticLabel: 'loading'),
                        error: (Object e, _) => ErrorState(
                          message: 'Could not load test accounts (${e is ApiFailure ? e.displayCode : 'E-APP'})',
                          retryLabel: 'Retry',
                          onRetry: () => ref.invalidate(_testAccountsProvider),
                        ),
                        data: (List<Map<String, dynamic>> list) => list.isEmpty
                            ? const EmptyState(icon: Icons.person_off_outlined, title: 'No seeded accounts')
                            : ListView(
                                children: <Widget>[
                                  for (final Map<String, dynamic> a in list)
                                    HastaListRow(
                                      key: Key('qa-${a['handle']}'),
                                      icon: Icons.person_outline,
                                      title: a['handle'] as String,
                                      subtitle: a['purpose'] as String?,
                                      enabled: _busy == null,
                                      onTap: () => _signIn(a['handle'] as String),
                                      trailing: IconButton(
                                        tooltip: 'Reset',
                                        icon: const Icon(Icons.restart_alt),
                                        onPressed: _busy == null ? () => _reset(a['handle'] as String) : null,
                                      ),
                                    ),
                                ],
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
