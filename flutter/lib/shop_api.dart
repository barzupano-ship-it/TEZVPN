import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'models.dart';

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.body,
    required this.reply,
    required this.created,
    required this.replied,
    this.fileName = '',
    this.fileMime = '',
  });

  final int id;
  final String body;
  final String reply;
  final int created;
  final int replied;
  final String fileName;
  final String fileMime;

  bool get hasFile => fileName.isNotEmpty;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    int num(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;
    final file = json['file'];
    var fileName = '';
    var fileMime = '';
    if (file is Map) {
      fileName = '${file['name'] ?? ''}';
      fileMime = '${file['mime'] ?? ''}';
    }
    return SupportTicket(
      id: num(json['id']),
      body: '${json['body'] ?? ''}',
      reply: '${json['reply'] ?? ''}',
      created: num(json['created']),
      replied: num(json['replied']),
      fileName: fileName,
      fileMime: fileMime,
    );
  }
}

class ShopApi {
  ShopApi(this._prefs);

  final SharedPreferences _prefs;
  final _client = http.Client();
  String protocol = 'awg';

  String get deviceFp {
    var id = _prefs.getString('fp');
    if (id == null || id.isEmpty) {
      const hex = '0123456789abcdef';
      final r = Random.secure();
      id = List.generate(32, (_) => hex[r.nextInt(16)]).join();
      _prefs.setString('fp', id);
    }
    return id;
  }

  Map<String, String> get _headers {
    final h = <String, String>{
      'Accept': 'application/json',
      'X-Tez-FP': deviceFp,
      'X-Tez-Tenant': ShopConfig.tenant,
      'X-Tez-Proto': protocol,
    };
    final cookie = _prefs.getString('cookie_value');
    if (cookie != null && cookie.isNotEmpty) {
      h['Cookie'] = 'tezweb=$cookie';
    }
    return h;
  }

  void _saveCookies(http.BaseResponse resp) {
    final raw = resp.headers['set-cookie'];
    if (raw == null) return;
    final m = RegExp(r'tezweb=([^;]+)').firstMatch(raw);
    if (m != null) {
      _prefs.setString('cookie_value', m.group(1)!);
    }
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? jsonBody,
  }) async {
    final uri = Uri.parse('${ShopConfig.shopUrl}$path');
    late http.Response resp;
    final headers = Map<String, String>.from(_headers);
    if (jsonBody != null) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    var attempt = 0;
    while (true) {
      try {
        if (method == 'POST') {
          resp = await _client.post(
            uri,
            headers: headers,
            body: jsonBody == null ? null : jsonEncode(jsonBody),
          );
        } else {
          resp = await _client.get(uri, headers: headers);
        }
        break;
      } catch (e) {
        attempt++;
        final text = e.toString();
        final again = attempt < 2 &&
            (text.contains('SocketException') ||
                text.contains('ClientException') ||
                text.contains('HandshakeException') ||
                text.contains('10057'));
        if (!again) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    _saveCookies(resp);
    Map<String, dynamic> obj = {};
    if (resp.body.startsWith('{')) {
      obj = jsonDecode(resp.body) as Map<String, dynamic>;
    }
    if (resp.statusCode >= 400) {
      final err = (obj['error'] as String?)?.trim();
      throw Exception((err == null || err.isEmpty) ? 'Ошибка ${resp.statusCode}' : err);
    }
    return obj;
  }

  Future<ShopState> state() async => parseState(await _request('/api/state'));

  Future<VpnConfig?> fetchConfig({String? oid}) async {
    try {
      final q = (oid != null && oid.isNotEmpty) ? '?oid=${Uri.encodeQueryComponent(oid)}' : '';
      final obj = await _request('/api/config$q');
      return _config((obj['config'] as Map?)?.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<ShopState> startOrder(String planId) async =>
      parseState(await _request('/api/order', method: 'POST', jsonBody: {'plan': planId}));

  Future<ShopState> setName(String name) async =>
      parseState(await _request('/api/name', method: 'POST', jsonBody: {'name': name}));

  Future<ShopState> login(String code) async {
    await _request('/api/login', method: 'POST', jsonBody: {'code': code});
    return state();
  }

  Future<ShopState> register(String login, String password) async {
    await _request('/api/register', method: 'POST', jsonBody: {
      'login': login,
      'password': password,
    });
    return state();
  }

  Future<ShopState> loginWithPassword(String login, String password) async {
    await _request('/api/login', method: 'POST', jsonBody: {
      'login': login,
      'password': password,
    });
    return state();
  }

  Future<({String challenge, String url})> startTelegramLogin() async {
    final obj = await _request('/api/auth/telegram/start', method: 'POST', jsonBody: {});
    final challenge = '${obj['challenge'] ?? ''}';
    final url = '${obj['url'] ?? ''}';
    if (challenge.isEmpty || url.isEmpty) {
      throw Exception('Не удалось начать вход через Telegram.');
    }
    return (challenge: challenge, url: url);
  }

  Future<({String code})> startDeviceLogin() async {
    final obj = await _request('/api/auth/device/start', method: 'POST', jsonBody: {});
    final code = '${obj['code'] ?? ''}'.trim();
    if (code.isEmpty) throw Exception('Не удалось создать код для другого телефона.');
    return (code: code);
  }

  Future<List<SupportTicket>> supportTickets() async {
    final obj = await _request('/api/support');
    final raw = obj['items'];
    if (raw is! List) return const [];
    return raw.map((item) => SupportTicket.fromJson((item as Map).cast<String, dynamic>())).toList();
  }

  Future<void> sendSupport(String text) async {
    await _request('/api/support', method: 'POST', jsonBody: {'text': text.trim()});
  }

  Future<void> sendSupportFile(List<int> bytes, String filename, String text) async {
    final uri = Uri.parse('${ShopConfig.shopUrl}/api/support/file');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_headers);
    final caption = text.trim();
    if (caption.isNotEmpty) req.fields['text'] = caption;
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await _client.send(req);
    final resp = await http.Response.fromStream(streamed);
    _saveCookies(resp);
    Map<String, dynamic> obj = {};
    if (resp.body.startsWith('{')) {
      obj = jsonDecode(resp.body) as Map<String, dynamic>;
    }
    if (resp.statusCode >= 400) {
      final err = (obj['error'] as String?)?.trim();
      throw Exception((err == null || err.isEmpty) ? 'Не удалось отправить файл' : err);
    }
  }

  Future<Uint8List> supportFile(int id) async {
    final uri = Uri.parse('${ShopConfig.shopUrl}/api/support/file/$id');
    final resp = await _client.get(uri, headers: _headers);
    _saveCookies(resp);
    if (resp.statusCode >= 400) {
      var err = '';
      if (resp.body.startsWith('{')) {
        final obj = jsonDecode(resp.body);
        if (obj is Map) err = '${obj['error'] ?? ''}'.trim();
      }
      throw Exception(err.isEmpty ? 'Файл не найден' : err);
    }
    return resp.bodyBytes;
  }

  Future<ShopState> claimDeviceLogin(String code) async {
    await _request('/api/auth/device/claim', method: 'POST', jsonBody: {'code': code.trim()});
    return state();
  }
  Future<String> pollTelegramLogin(String challenge) async {
    final obj = await _request('/api/auth/telegram/poll', method: 'POST', jsonBody: {
      'challenge': challenge,
    });
    return '${obj['status'] ?? ''}';
  }

  Future<ShopState> uploadReceipt(List<int> bytes, String filename) async {
    final uri = Uri.parse('${ShopConfig.shopUrl}/api/receipt');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_headers);
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    final streamed = await _client.send(req);
    final resp = await http.Response.fromStream(streamed);
    _saveCookies(resp);
    Map<String, dynamic> obj = {};
    if (resp.body.startsWith('{')) {
      obj = jsonDecode(resp.body) as Map<String, dynamic>;
    }
    if (resp.statusCode >= 400) {
      final err = (obj['error'] as String?)?.trim();
      throw Exception((err == null || err.isEmpty) ? 'Не удалось отправить чек' : err);
    }
    return parseState(obj.containsKey('plans') ? obj : await _request('/api/state'));
  }

  static ShopState parseState(Map<String, dynamic> obj) {
    final plans = (obj['plans'] as List? ?? [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(_plan)
        .whereType<Plan>()
        .toList();
    final orders = (obj['orders'] as List? ?? [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(_order)
        .whereType<Order>()
        .toList();
    final order = _order((obj['order'] as Map?)?.cast<String, dynamic>() ?? {});
    final pay = (obj['pay'] as Map?)?.cast<String, dynamic>() ?? {};
    final meta = (obj['meta'] as Map?)?.cast<String, dynamic>() ?? {};
    final acc = (obj['account'] as Map?)?.cast<String, dynamic>();
    return ShopState(
      plans: plans,
      pay: PayInfo(
        alif: '${pay['alif'] ?? ''}',
        dc: '${pay['dc'] ?? ''}',
        payee: '${pay['payee'] ?? ''}',
        support: '${pay['support'] ?? ''}',
        wechat: pay['wechat'] == true,
        alipay: pay['alipay'] == true,
      ),
      order: order,
      orders: orders.isEmpty ? [if (order != null) order] : orders,
      config: _config((obj['config'] as Map?)?.cast<String, dynamic>()),
      account: acc == null
          ? null
          : Account(
              code: '${acc['code'] ?? ''}',
              login: '${acc['login'] ?? ''}',
            ),
      meta: Meta(
        title: (meta['title'] as String?)?.isNotEmpty == true ? meta['title'] as String : ShopConfig.appName,
        bot: (meta['bot'] as String?)?.isNotEmpty == true ? meta['bot'] as String : 'teztezvpn_bot',
        support: (meta['support'] as String?)?.isNotEmpty == true
            ? meta['support'] as String
            : ShopConfig.support,
      ),
      flash: (obj['flash'] as String?)?.isEmpty == true ? null : obj['flash'] as String?,
    );
  }

  static Plan? _plan(Map<String, dynamic> o) {
    final id = '${o['id'] ?? ''}';
    if (id.isEmpty) return null;
    return Plan(
      id: id,
      title: '${o['title'] ?? id}',
      tjs: (o['tjs'] as num?)?.toDouble() ?? 0,
      cny: (o['cny'] as num?)?.toDouble() ?? 0,
      devices: (o['devices'] as num?)?.toInt() ?? 1,
      expires: '${o['expires'] ?? ''}',
    );
  }

  static Order? _order(Map<String, dynamic> o) {
    final id = '${o['id'] ?? ''}';
    if (id.isEmpty) return null;
    final st = '${o['status'] ?? ''}';
    return Order(
      id: id,
      plan: '${o['plan'] ?? ''}',
      title: '${o['title'] ?? ''}',
      amount: '${o['amount'] ?? ''}'.replaceAll('.0', ''),
      status: st,
      statusLabel: '${o['status_label'] ?? st}',
      name: '${o['name'] ?? ''}',
      ready: o['ready'] == true || st == 'fulfilled',
    );
  }

  static VpnConfig? _config(Map<String, dynamic>? obj) {
    if (obj == null) return null;
    final devices = (obj['devices'] as List? ?? [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map((d) {
          final conf = '${d['conf'] ?? ''}';
          if (conf.isEmpty) return null;
          return VpnDevice(
            name: '${d['name'] ?? ''}',
            conf: conf,
            vpnuri: '${d['vpnuri'] ?? ''}',
            xray: '${d['xray'] ?? ''}',
            hysteria2: '${d['hysteria2'] ?? d['hy2'] ?? ''}',
            sub: '${d['sub'] ?? ''}',
          );
        })
        .whereType<VpnDevice>()
        .toList();
    if (devices.isEmpty) return null;
    return VpnConfig(sid: '${obj['sid'] ?? ''}', devices: devices);
  }
}
