# ADR-0009 — flutter_web_auth_2 for Gmail linking (mobile)

Status: accepted (PR #3c, HAS-300).

## Decision
`apps/mobile` depends on `flutter_web_auth_2` pinned at exactly `4.1.0` (no `^`); `pubspec.lock` is committed. It is imported only by `lib/features/linked_accounts/data/google_auth_launcher.dart`, behind the `GoogleAuthLauncher` interface. It opens the server-built `auth_url` in ASWebAuthenticationSession (iOS) or Custom Tabs (Android) and returns the `hasta://link/google?code&state` redirect that the server's `link:callback` issues.

## Why 4.1.0, not the latest
- 6.x requires Flutter ≥ 3.47; we are on 3.24.5.
- 5.x requires compileSdk 36 and androidx.browser 1.9.0. That means an AGP/Gradle upgrade (we are on AGP 8.1.0, Gradle 8.3), which is out of scope.
- 4.1.0 uses compileSdk 34, androidx.browser 1.8.0, minSdk 21 (ours is 24), and iOS 11 (ours is 12; custom-scheme callbacks use `ASWebAuthenticationSession(url:callbackURLScheme:)`).
- Transitive packages: `url_launcher`, `desktop_webview_window 0.2.3` and `window_to_front`. The last two are desktop-only and never registered on mobile.

## Guardrails
- This is linking, not sign-in. `google_sign_in` and `sign_in_with_apple` stay banned (gates `mobile-deps`, which now checks pubspec and `import` lines).
- The app never builds a Google URL, holds a client id or sees an id_token. It launches `auth_url` as returned, checks that the callback `state` equals the `link:start` state, and posts exactly `{state, code}` to `link:complete`. `device_token` is not sent because the session (T46) and the Redis state are already device-bound.
- `access_denied` and a user-closed browser both map to `AuthCancelled` (DS `permissionDenied`).
- Android: `CallbackActivity` is limited to `hasta://link`. iOS needs no URL type.

## Alternatives rejected
`url_launcher` plus app links (we would hand-roll callback routing and the cancel detection); `google_sign_in` (sign-in SDK, banned by v1); an in-app WebView (Google blocks embedded OAuth).
