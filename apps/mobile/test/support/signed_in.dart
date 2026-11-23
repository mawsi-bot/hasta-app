import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/db/drift/app_database.dart';
import 'package:hasta/core/security/token_store.dart';

import 'harness.dart';

const String kAccountId = '01934f00-0000-7000-8000-000000000001';

/// Seeds a signed-in guest (as after T40) so the app boots into Home.
Future<Harness> signedInHarness(WidgetTester tester, {bool online = true, bool withProfile = true}) async {
  final Harness h = Harness(online: online);
  await h.tokens.write(SecureKey.deviceToken, 'dt_1');
  await h.tokens.write(SecureKey.accessToken, 'at_1');
  await h.tokens.write(SecureKey.refreshToken, 'rt_1');
  await tester.runAsync(() async {
    await h.db.into(h.db.localAccounts).insert(LocalAccountsCompanion.insert(
        id: kAccountId, isGuest: true, status: 'active', createdAt: DateTime.utc(2026), syncedAt: DateTime.utc(2026)));
    if (withProfile) {
      await h.db
          .into(h.db.localProfiles)
          .insert(LocalProfilesCompanion.insert(accountId: kAccountId, updatedAt: DateTime.utc(2026)));
    }
  });
  return h;
}
