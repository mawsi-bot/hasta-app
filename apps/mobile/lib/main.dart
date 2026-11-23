import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/build_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  assert(BuildConfig.apiBaseUrl.isNotEmpty, 'Pass --dart-define-from-file=dart_defines/<env>.json');
  runApp(const ProviderScope(child: HastaApp()));
}
