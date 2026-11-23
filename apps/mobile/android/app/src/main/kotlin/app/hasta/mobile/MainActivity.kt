package app.hasta.mobile

import android.annotation.SuppressLint
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes a stable per-install device identifier to Dart.
 * The raw value is only ever HMAC-hashed server-side (PRD §5.3); it is never
 * logged or persisted by the app outside secure storage.
 */
class MainActivity : FlutterActivity() {
    @SuppressLint("HardwareIds")
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.hasta.mobile/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "deviceId" -> result.success(
                        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                    )
                    "platform" -> result.success("android")
                    else -> result.notImplemented()
                }
            }
    }
}
