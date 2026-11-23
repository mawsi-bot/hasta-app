import 'package:drift/drift.dart';

/// Hasta ships Android/iOS only. Non-FFI targets (used solely for the CI
/// release-artefact check T36) have no local database.
QueryExecutor openConnection() => throw UnsupportedError('Local database requires dart:ffi');
