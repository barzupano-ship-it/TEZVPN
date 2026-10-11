import 'dart:convert';

import 'package:flutter/services.dart';

class ShopConfig {
  static String appName = 'TEZVPN';
  static String shopUrl = 'https://188-116-24-47.sslip.io';
  static String support = 'BarzuRizoev';
  static String tunnelId = 'ru.tezvpn.app.tunnel';
  static String tenant = 'tez';
  static Color gold = const Color(0xFFF5C518);
  static Color navy = const Color(0xFF0C2438);
  static Color card = const Color(0xFF16324F);

  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/brand.json');
      final data = jsonDecode(raw);
      if (data is! Map) return;
      appName = _text(data['appName'], appName, 24);
      shopUrl = _url(data['shopUrl'], shopUrl);
      support = _user(data['support'], support);
      tenant = _user(data['tenant'], tenant).toLowerCase();
      gold = _color(data['gold'], gold);
      navy = _color(data['navy'], navy);
      card = _color(data['card'], card);
    } catch (_) {}
  }

  static String _text(Object? raw, String fallback, int max) {
    final value = (raw ?? '').toString().trim();
    if (value.length < 2) return fallback;
    return value.length <= max ? value : value.substring(0, max);
  }

  static String _url(Object? raw, String fallback) {
    final value = (raw ?? '').toString().trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return fallback;
    return value;
  }

  static String _user(Object? raw, String fallback) {
    var value = (raw ?? '').toString().trim();
    if (value.startsWith('@')) value = value.substring(1);
    if (!RegExp(r'^[A-Za-z0-9_]{2,32}$').hasMatch(value)) return fallback;
    return value;
  }

  static Color _color(Object? raw, Color fallback) {
    var hex = (raw ?? '').toString().trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (!RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(hex)) return fallback;
    return Color(int.parse(hex, radix: 16));
  }
}
