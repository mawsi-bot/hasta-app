import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity/connectivity.dart';
import 'db/drift/app_database.dart';
import 'network/api_client.dart';
import 'security/device_identity.dart';
import 'security/token_store.dart';
import 'sync/hlc.dart';

/// Composition root. Tests override these providers with fakes.
final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>((Ref ref) => SecureTokenStore());

final Provider<DeviceIdentity> deviceIdentityProvider =
    Provider<DeviceIdentity>((Ref ref) => const PlatformDeviceIdentity());

final Provider<ConnectivitySignal> connectivityProvider =
    Provider<ConnectivitySignal>((Ref ref) => PlatformConnectivity());

/// `true` when a network interface is available. Defaults to online until known.
final StreamProvider<bool> onlineProvider =
    StreamProvider<bool>((Ref ref) => ref.watch(connectivityProvider).watch());

final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((Ref ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final Provider<ApiClient> apiClientProvider =
    Provider<ApiClient>((Ref ref) => ApiClient(tokens: ref.watch(tokenStoreProvider)));

final Provider<Hlc> hlcProvider = Provider<Hlc>((Ref ref) => Hlc());

/// UI language — Myanmar first (SKILL rule 7). Stored locally (works offline).
final StreamProvider<Locale> localeProvider = StreamProvider<Locale>((Ref ref) =>
    ref.watch(databaseProvider).kvWatch('ui.locale').map((String? v) => Locale(v ?? 'my')));

extension OnlineX on WidgetRef {
  bool get isOnline => watch(onlineProvider).valueOrNull ?? true;
}
