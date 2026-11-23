import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/ids/uuid_v7.dart';
import 'package:hasta/core/sync/hlc.dart';

void main() {
  group('UUIDv7 (SKILL rule 9)', () {
    test('format, version and variant', () {
      final String id = uuidV7();
      expect(id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    });
    test('embeds the timestamp and sorts by time', () {
      final DateTime t = DateTime.utc(2026, 11, 23, 1, 2, 3, 456);
      expect(uuidV7Millis(uuidV7(now: t)), t.millisecondsSinceEpoch);
      final String a = uuidV7(now: t);
      final String b = uuidV7(now: t.add(const Duration(milliseconds: 1)));
      expect(a.compareTo(b), lessThan(0));
    });
  });

  group('HLC (field-level LWW, SPEC §11.3)', () {
    test('strictly increasing under a frozen clock', () {
      final Hlc h = Hlc(clock: () => 1000);
      final List<String> v = List<String>.generate(5, (_) => h.next());
      for (int i = 1; i < v.length; i++) {
        expect(Hlc.compare(v[i], v[i - 1]), 1);
      }
      expect(v.first, Hlc.encode(1000, 0));
    });
    test('observe(remote) makes the next stamp greater than remote', () {
      final Hlc h = Hlc(clock: () => 1000);
      final String remote = Hlc.encode(5000, 7);
      h.observe(remote);
      expect(Hlc.compare(h.next(), remote), 1);
    });
    test('encoding matches the server decimal format (ms<<16)|counter', () {
      expect(Hlc.encode(1, 2), '65538');
    });
  });
}
