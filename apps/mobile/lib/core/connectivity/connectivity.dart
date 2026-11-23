import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Online/offline signal. Offline means "no network interface"; a reachable
/// interface with a failing server is surfaced as an error state instead.
abstract interface class ConnectivitySignal {
  Future<bool> isOnline();
  Stream<bool> watch();
}

class PlatformConnectivity implements ConnectivitySignal {
  PlatformConnectivity([Connectivity? c]) : _c = c ?? Connectivity();
  final Connectivity _c;

  static bool _online(List<ConnectivityResult> r) => r.any((ConnectivityResult x) => x != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async => _online(await _c.checkConnectivity());

  @override
  Stream<bool> watch() => _c.onConnectivityChanged.map(_online).distinct();
}

/// Test/manual implementation.
class ManualConnectivity implements ConnectivitySignal {
  ManualConnectivity({bool online = true}) : _online = online;
  bool _online;
  final StreamController<bool> _ctrl = StreamController<bool>.broadcast();

  set online(bool v) {
    _online = v;
    _ctrl.add(v);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> watch() async* {
    yield _online;
    yield* _ctrl.stream;
  }
}
