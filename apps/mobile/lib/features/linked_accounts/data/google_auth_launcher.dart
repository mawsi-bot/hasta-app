import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// The user closed the browser sheet / denied consent (DS `permissionDenied`).
class AuthCancelled implements Exception {
  const AuthCancelled();
}

/// Browser boundary for Gmail LINKING (SPEC 1.0.2 §5.4, ADR-0009). Opens the server-built `auth_url` in
/// ASWebAuthenticationSession (iOS) / Custom Tabs (Android) and returns the `hasta://` callback URI.
/// The app never builds the Google URL, never holds a client id and never sees an id_token.
abstract interface class GoogleAuthLauncher {
  Future<Uri> authenticate(Uri authUrl, String callbackScheme);
}

class WebAuthGoogleLauncher implements GoogleAuthLauncher {
  const WebAuthGoogleLauncher();

  @override
  Future<Uri> authenticate(Uri authUrl, String callbackScheme) async {
    try {
      return Uri.parse(await FlutterWebAuth2.authenticate(url: authUrl.toString(), callbackUrlScheme: callbackScheme));
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') throw const AuthCancelled();
      rethrow;
    }
  }
}

final Provider<GoogleAuthLauncher> googleAuthLauncherProvider =
    Provider<GoogleAuthLauncher>((Ref ref) => const WebAuthGoogleLauncher());
