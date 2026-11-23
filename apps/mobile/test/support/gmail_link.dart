import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/features/linked_accounts/data/google_auth_launcher.dart';

import 'harness.dart';
import 'signed_in.dart';

/// Stands in for the browser. Default: Google redirects back with the state it was given.
class FakeLauncher implements GoogleAuthLauncher {
  final List<Uri> launched = <Uri>[];
  FutureOr<Uri> Function(Uri url) respond = (Uri u) => Uri.parse('hasta://link/google?code=c-1&state=${u.queryParameters['state']}');

  @override
  Future<Uri> authenticate(Uri authUrl, String callbackScheme) async {
    expect(callbackScheme, 'hasta');
    launched.add(authUrl);
    return respond(authUrl);
  }
}

const String kStart = '/v1/auth/identities/google/link:start';
const String kComplete = '/v1/auth/identities/google/link:complete';
const String kIdentity = '/v1/auth/identities/google';
int linkStates = 0;
String authUrl(String state) => 'https://accounts.google.com/o/oauth2/v2/auth?client_id=server-owned&state=$state&nonce=n';
String get lastState => 'st-$linkStates';
FakeResponse startOk() {
  final String s = 'st-${++linkStates}';
  return FakeResponse(200, <String, dynamic>{'state': s, 'nonce': 'n', 'scopes': <String>['openid'], 'auth_url': authUrl(s), 'expires_in': 300});
}

FakeResponse linkedOk(String masked) => FakeResponse(200, <String, dynamic>{
      'identity': <String, dynamic>{'provider': 'google', 'email_masked': masked, 'linked_at': '2026-11-23T00:00:00.000Z'},
      'account': <String, dynamic>{'id': kAccountId, 'is_guest': false},
      'unlocked': <String>['premium_purchase', 'restore_purchases', 'device_recovery'],
    });
