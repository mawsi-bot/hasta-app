import 'package:flutter/services.dart';

/// Platform device identifier (Android ID / iOS identifierForVendor) read via a
/// native MethodChannel (no extra dependency). The raw value is sent once over
/// TLS to `POST /v1/auth/device/register`, where it is HMAC-hashed with a
/// server-side pepper; the app never logs or persists it (SPEC §5.3).
abstract interface class DeviceIdentity {
  Future<String> rawDeviceId();
  Future<String> platform();
}

class PlatformDeviceIdentity implements DeviceIdentity {
  const PlatformDeviceIdentity();

  static const MethodChannel _channel = MethodChannel('app.hasta.mobile/device');

  @override
  Future<String> rawDeviceId() async {
    final String? id = await _channel.invokeMethod<String>('deviceId');
    if (id == null || id.isEmpty) {
      throw StateError('device id unavailable');
    }
    return id;
  }

  @override
  Future<String> platform() async => (await _channel.invokeMethod<String>('platform')) ?? 'android';
}
