/// Hybrid Logical Clock encoded as `(wallMs << 16) | counter`, serialised as a
/// decimal string (matches the server's PATCH /v1/profile `hlc`, SPEC §11.3).
///
/// BigInt keeps the 64-bit value exact on every backend.
class Hlc {
  Hlc({int Function()? clock}) : _clock = clock ?? (() => DateTime.now().toUtc().millisecondsSinceEpoch);

  final int Function() _clock;
  int _lastMs = 0;
  int _counter = 0;

  static final BigInt _mask = BigInt.from(0xffff);

  /// Next local timestamp; strictly increasing for this instance.
  String next() {
    final int now = _clock();
    if (now > _lastMs) {
      _lastMs = now;
      _counter = 0;
    } else {
      _counter++;
      if (_counter > 0xffff) {
        _lastMs++;
        _counter = 0;
      }
    }
    return encode(_lastMs, _counter);
  }

  /// Merge a remote timestamp so subsequent [next] values are greater.
  void observe(String remote) {
    final BigInt v = BigInt.tryParse(remote) ?? BigInt.zero;
    final int ms = (v >> 16).toInt();
    final int c = (v & _mask).toInt();
    if (ms > _lastMs || (ms == _lastMs && c > _counter)) {
      _lastMs = ms;
      _counter = c;
    }
  }

  static String encode(int ms, int counter) => ((BigInt.from(ms) << 16) | BigInt.from(counter)).toString();

  static int compare(String a, String b) => (BigInt.tryParse(a) ?? BigInt.zero).compareTo(BigInt.tryParse(b) ?? BigInt.zero);
}
