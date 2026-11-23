# ADR-0004 — Native device-id MethodChannel; path_provider + path for Drift

Status: accepted (Sprint 1)

## Decision
Instead of a third-party device-id plugin, a 20-line platform channel `app.hasta.mobile/device` returns `Settings.Secure.ANDROID_ID` (Android) and `identifierForVendor` (iOS). The raw id never leaves memory: the client sends it once over TLS to `/auth/device/register`, where it is HMAC-ed with the pepper; nothing raw is logged or stored.

`path_provider 2.1.4` and `path 1.9.0` are added because Drift's native connection needs the documents directory. Both are first-party Flutter/Dart packages.
