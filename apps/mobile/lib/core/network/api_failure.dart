/// Client view of the API error envelope (API contract §0):
/// `{ error: { code, message_key, details, request_id } }`.
class ApiFailure implements Exception {
  const ApiFailure({
    required this.code,
    this.status,
    this.messageKey,
    this.details,
    this.requestId,
    this.retryAfterSeconds,
  });

  /// Transport failure — no response reached the app.
  const ApiFailure.offline() : this(code: offlineCode);

  static const String offlineCode = 'network_unreachable';

  final String code;
  final int? status;
  final String? messageKey;
  final Map<String, dynamic>? details;
  final String? requestId;
  final int? retryAfterSeconds;

  bool get isOffline => code == offlineCode;

  /// Hidden code shown at the end of error copy, per the DS error formula
  /// `[what happened] + [what to do] + [(hidden) error code]`.
  String get displayCode => isOffline ? 'E-NET' : 'E-${status ?? 0}';

  /// Remaining cooldown days for `device_cooldown` (T42).
  int? get retryAfterDays {
    final Object? v = details?['retry_after_days'];
    return v is num ? v.toInt() : null;
  }

  @override
  String toString() => 'ApiFailure($code, status=$status, request_id=$requestId)';
}
