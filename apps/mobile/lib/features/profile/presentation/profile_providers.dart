import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/drift/app_database.dart';
import '../../auth/domain/auth_controller.dart';

final StreamProvider<LocalProfile?> myProfileProvider = StreamProvider<LocalProfile?>((Ref ref) {
  final String? id = ref.watch(authControllerProvider.select((s) => s.account?.id));
  if (id == null) return Stream<LocalProfile?>.value(null);
  return ref.watch(profileRepositoryProvider).watch(id);
});

final StreamProvider<int> profilePendingProvider =
    StreamProvider<int>((Ref ref) => ref.watch(profileRepositoryProvider).watchPending());

final StreamProvider<String?> profileSyncErrorProvider =
    StreamProvider<String?>((Ref ref) => ref.watch(profileRepositoryProvider).watchSyncError());

/// Background refresh from `/v1/me`; the UI renders Drift regardless.
final FutureProvider<void> profileRefreshProvider = FutureProvider<void>((Ref ref) async {
  final String? id = ref.watch(authControllerProvider.select((s) => s.account?.id));
  if (id == null) return;
  await ref.read(profileRepositoryProvider).refresh(id);
});
