import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() => LazyDatabase(() async {
      final Directory dir = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(File(p.join(dir.path, 'hasta.sqlite')));
    });
