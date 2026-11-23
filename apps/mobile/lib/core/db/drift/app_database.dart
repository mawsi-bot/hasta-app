import 'package:drift/drift.dart';

import 'connection/connection.dart' as conn;

part 'app_database.g.dart';

/// Local source of truth (SKILL rule 4, SPEC §11). UI reads these tables via
/// streams; network responses are upserted here first.
class LocalAccounts extends Table {
  TextColumn get id => text()();
  BoolColumn get isGuest => boolean()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class LocalProfiles extends Table {
  TextColumn get accountId => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get username => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get birthDate => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();

  /// JSON map field -> HLC of the latest local edit (field-level LWW).
  TextColumn get fieldHlc => text().withDefault(const Constant('{}'))();
  TextColumn get serverHlc => text().withDefault(const Constant('0'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{accountId};
}

/// Durable write queue. Each entry keeps its Idempotency-Key across retries.
class OutboxEntries extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get payload => text()();
  TextColumn get idempotencyKey => text()();

  /// pending | failed (snake_case enum, SKILL rule 9)
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get lastErrorCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class KvEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

@DriftDatabase(tables: <Type>[LocalAccounts, LocalProfiles, OutboxEntries, KvEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        // Future versions add explicit, tested steps here (no destructive migrations).
      );

  /// Number of queued (not yet acknowledged) writes of [kind] — drives the
  /// "waiting" badge.
  Stream<int> watchPending(String kind) => (select(outboxEntries)
        ..where(($OutboxEntriesTable t) => t.kind.equals(kind) & t.status.equals('pending')))
      .watch()
      .map((List<OutboxEntry> r) => r.length);

  Future<String?> kvGet(String key) async =>
      (await (select(kvEntries)..where((KvEntries t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> kvSet(String key, String value) =>
      into(kvEntries).insertOnConflictUpdate(KvEntriesCompanion.insert(key: key, value: value));

  Stream<String?> kvWatch(String key) =>
      (select(kvEntries)..where((KvEntries t) => t.key.equals(key))).watchSingleOrNull().map((KvEntry? e) => e?.value);

  /// Wipes everything bound to the signed-in account (logout / session revoked).
  Future<void> clearAccountData() => transaction(() async {
        await delete(outboxEntries).go();
        await delete(localProfiles).go();
        await delete(localAccounts).go();
      });
}
