import 'package:flutter/services.dart';

class VpnChannel {
  static const _ch = MethodChannel('ru.tezvpn.app/vpn');

  Future<bool> prepare() async {
    try {
      final ok = await _ch.invokeMethod<bool>('prepare');
      return ok == true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> connect(String conf, {String protocol = 'awg'}) async {
    try {
      await _ch.invokeMethod('connect', {'conf': conf, 'protocol': protocol});
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Не удалось включить SULTAN VPN');
    }
  }

  Future<void> setKillSwitch(bool enabled) async {
    try {
      await _ch.invokeMethod('setKillSwitch', {'enabled': enabled});
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Не удалось включить аварийное отключение');
    }
  }

  Future<List<({String package, String label})>> launchableApps() async {
    try {
      final raw = await _ch.invokeMethod<List<dynamic>>('launchableApps');
      return (raw ?? const []).map((item) {
        final map = (item as Map).cast<dynamic, dynamic>();
        return (package: '${map['package'] ?? ''}', label: '${map['label'] ?? ''}');
      }).where((app) => app.package.isNotEmpty).toList();
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  Future<void> disconnect() async {
    try {
      await _ch.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Не удалось выключить SULTAN VPN');
    }
  }

  Future<({int up, int down})> traffic() async {
    try {
      final raw = await _ch.invokeMethod<Map<dynamic, dynamic>>('traffic');
      final up = raw?['up'];
      final down = raw?['down'];
      return (up: up is int ? up : 0, down: down is int ? down : 0);
    } catch (_) {
      return (up: 0, down: 0);
    }
  }

  Future<bool> isUp() async {
    try {
      final ok = await _ch.invokeMethod<bool>('isUp');
      return ok == true;
    } catch (_) {
      return false;
    }
  }
}
