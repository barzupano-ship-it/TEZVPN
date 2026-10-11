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
      throw Exception(e.message ?? 'Не удалось включить TEZVPN');
    }
  }

  Future<void> disconnect() async {
    try {
      await _ch.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Не удалось выключить TEZVPN');
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
