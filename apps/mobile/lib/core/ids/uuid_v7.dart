import 'dart:math';

final Random _rng = Random.secure();

/// RFC 9562 UUIDv7 (48-bit unix ms + random). Used for client-generated ids,
/// Idempotency-Key and X-Request-Id (SKILL rule 9).
///
/// Arithmetic uses `~/` instead of shifts so the result is identical on the
/// JS backend (bitwise ops there truncate to 32 bits).
String uuidV7({DateTime? now}) {
  final int ms = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
  final List<int> b = List<int>.generate(16, (_) => _rng.nextInt(256));
  b[0] = (ms ~/ 1099511627776) % 256; // 2^40
  b[1] = (ms ~/ 4294967296) % 256; // 2^32
  b[2] = (ms ~/ 16777216) % 256; // 2^24
  b[3] = (ms ~/ 65536) % 256;
  b[4] = (ms ~/ 256) % 256;
  b[5] = ms % 256;
  b[6] = 0x70 | (b[6] & 0x0f);
  b[8] = 0x80 | (b[8] & 0x3f);
  final String hex = b.map((int x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Extracts the embedded timestamp (ms) — used in tests for monotonicity.
int uuidV7Millis(String id) => int.parse(id.replaceAll('-', '').substring(0, 12), radix: 16);
