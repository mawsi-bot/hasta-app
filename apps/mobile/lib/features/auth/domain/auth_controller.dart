import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/providers.dart';
import '../../../core/sync/outbox_worker.dart';
import '../../profile/data/profile_repository.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((Ref ref) => AuthRepository(
      api: ref.watch(apiClientProvider),
      tokens: ref.watch(tokenStoreProvider),
      device: ref.watch(deviceIdentityProvider),
      db: ref.watch(databaseProvider),
    ));

final Provider<OutboxWorker> outboxWorkerProvider = Provider<OutboxWorker>((Ref ref) {
  final OutboxWorker w = OutboxWorker(
    db: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityProvider),
    handlers: <String, OutboxHandler>{
      kProfilePatch: OutboxHandler(
        send: (Map<String, dynamic> p, String k) => ref.read(profileRepositoryProvider).sendPatch(p, k),
        onRejected: (Map<String, dynamic> p, ApiFailure f) => ref.read(profileRepositoryProvider).onRejected(p, f),
      ),
    },
  );
  ref.onDispose(w.stop);
  return w;
});

final Provider<ProfileRepository> profileRepositoryProvider = Provider<ProfileRepository>((Ref ref) => ProfileRepository(
      db: ref.watch(databaseProvider),
      api: ref.watch(apiClientProvider),
      hlc: ref.watch(hlcProvider),
      enqueue: (String kind, Map<String, dynamic> payload) => ref.read(outboxWorkerProvider).enqueue(kind, payload),
      kick: () => unawaited(ref.read(outboxWorkerProvider).drain()),
    ));

final NotifierProvider<AuthController, AuthState> authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    ref.read(apiClientProvider).onSessionExpired = () => unawaited(_onSessionExpired());
    unawaited(_boot());
    return const AuthState.booting();
  }

  Future<void> _boot() async {
    final AccountSummary? s = await _repo.restore();
    if (s == null) {
      state = const AuthState.signedOut();
    } else {
      _signedIn(s);
    }
  }

  /// Welcome primary CTA (single button).
  Future<void> continueAsGuest({String locale = 'my'}) async {
    if (state.phase == AuthPhase.signingIn) return; // double-tap guard
    state = const AuthState.signingIn();
    try {
      _signedIn(await _repo.continueAsGuest(locale: locale));
    } on ApiFailure catch (f) {
      state = AuthState.signedOut(issue: WelcomeIssue.fromFailure(f));
    } on Object {
      state = const AuthState.signedOut(issue: FailureIssue('E-APP'));
    }
  }

  /// Used by QA quick-test accounts (dev/test/beta builds only).
  Future<void> adoptSession(Map<String, dynamic> sessionResponse) async {
    _signedIn(await _repo.adoptSession(sessionResponse));
  }

  Future<void> signOut() async {
    await ref.read(outboxWorkerProvider).stop();
    await _repo.signOut();
    state = const AuthState.signedOut();
  }

  Future<void> _onSessionExpired() async {
    await ref.read(outboxWorkerProvider).stop();
    await _repo.clearLocalSession();
    state = const AuthState.signedOut();
  }

  void _signedIn(AccountSummary s) {
    state = AuthState.signedIn(s);
    final OutboxWorker w = ref.read(outboxWorkerProvider)..start();
    unawaited(w.drain());
  }
}
