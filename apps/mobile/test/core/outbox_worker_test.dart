import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/connectivity/connectivity.dart';
import 'package:hasta/core/db/drift/app_database.dart';
import 'package:hasta/core/network/api_failure.dart';
import 'package:hasta/core/sync/outbox_worker.dart';

void main() {
  late AppDatabase db;
  late ManualConnectivity net;
  late List<String> sentKeys;
  late List<String> rejected;
  late ApiFailure? nextFailure;
  DateTime now = DateTime.utc(2026, 11, 23);

  OutboxWorker worker() => OutboxWorker(
        db: db,
        connectivity: net,
        now: () => now,
        handlers: <String, OutboxHandler>{
          'k': OutboxHandler(
            send: (Map<String, dynamic> p, String key) async {
              if (nextFailure != null) {
                final ApiFailure f = nextFailure!;
                nextFailure = null;
                throw f;
              }
              sentKeys.add('${p['n']}:$key');
            },
            onRejected: (Map<String, dynamic> p, ApiFailure f) async => rejected.add('${p['n']}:${f.code}'),
          ),
        },
      );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    net = ManualConnectivity(online: false);
    sentKeys = <String>[];
    rejected = <String>[];
    nextFailure = null;
    now = DateTime.utc(2026, 11, 23);
  });
  tearDown(() => db.close());

  test('offline: entries persist; online: drained in order', () async {
    final OutboxWorker w = worker();
    await w.enqueue('k', <String, dynamic>{'n': 1});
    now = now.add(const Duration(milliseconds: 1));
    await w.enqueue('k', <String, dynamic>{'n': 2});
    await w.drain();
    expect(sentKeys, isEmpty);
    expect(await w.pendingCount(), 2);
    net.online = true;
    await w.drain();
    expect(sentKeys.map((String s) => s.split(':').first), <String>['1', '2']);
    expect(await w.pendingCount(), 0);
  });

  test('transient failure (503) keeps the SAME Idempotency-Key on retry and backs off', () async {
    net.online = true;
    final OutboxWorker w = worker();
    await w.enqueue('k', <String, dynamic>{'n': 1});
    final String key = (await db.select(db.outboxEntries).getSingle()).idempotencyKey;
    nextFailure = const ApiFailure(code: 'internal_error', status: 503);
    await w.drain();
    final OutboxEntry e = await db.select(db.outboxEntries).getSingle();
    expect(e.attempts, 1);
    expect(e.nextAttemptAt.isAfter(now), isTrue);
    await w.drain(); // not yet due
    expect(sentKeys, isEmpty);
    now = now.add(const Duration(minutes: 10));
    await w.drain();
    expect(sentKeys, <String>['1:$key']);
  });

  test('permanent rejection (409 username_taken) marks failed and notifies', () async {
    net.online = true;
    final OutboxWorker w = worker();
    await w.enqueue('k', <String, dynamic>{'n': 7});
    nextFailure = const ApiFailure(code: 'username_taken', status: 409);
    await w.drain();
    expect(rejected, <String>['7:username_taken']);
    expect((await db.select(db.outboxEntries).getSingle()).status, 'failed');
    expect(await w.pendingCount(), 0);
  });
}
