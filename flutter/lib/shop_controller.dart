import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'shop_api.dart';
import 'vpn_channel.dart';
import 'l10n.dart';

class ShopController extends ChangeNotifier {
  ShopApi? _api;
  final vpn = VpnChannel();
  L10n l10n = L10n('ru');

  bool loading = true;
  bool busy = false;
  bool connecting = false;
  bool vpnOn = false;
  ShopState shop = const ShopState();
  String? error;
  String? message;
  final nameCtrl = TextEditingController();
  final loginCtrl = TextEditingController();
  String screen = 'home';
  bool _polling = false;
  bool _watching = false;
  bool _userOff = false;
  String? _armedOid;
  String? _savedConf;
  String protocol = 'awg';
  String? _seenStatus;
  Timer? _tick;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    l10n = L10n(prefs.getString('lang') == 'en' ? 'en' : 'ru');
    _savedConf = prefs.getString('vpn_conf');
    protocol = 'awg';
    await prefs.remove('vpn_proto');
    _api = ShopApi(prefs)..protocol = 'awg';
    _armWatch();
    await _prepareVpn();
    await refresh();
  }

  void _armWatch() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_watch());
    });
  }

  Future<void> onAppResumed() async {
    vpnOn = await vpn.isUp();
    notifyListeners();
    await _watch();
  }

  Future<void> setLang(String code) async {
    l10n = L10n(code == 'en' ? 'en' : 'ru');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', l10n.code);
    notifyListeners();
  }

  ShopApi get api => _api!;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      shop = await api.state();
      _apply(shop, loading: false);
      await _pullConfig();
      await maybeAutoConnect();
    } catch (e) {
      loading = false;
      error = _err(e);
    }
    notifyListeners();
  }

  Future<void> buy(String planId) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await api.startOrder(planId);
      shop = await api.state();
      final code = shop.account?.code ?? '';
      _apply(
        shop,
        busy: false,
        screen: 'account',
        message: code.isEmpty ? null : l10n.cabinetReady(code),
      );
    } catch (e) {
      busy = false;
      error = _err(e);
    }
    notifyListeners();
  }

  Future<void> submitName() async {
    final name = nameCtrl.text.trim();
    if (name.length < 2) {
      error = l10n.enterName;
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await api.setName(name);
      shop = await api.state();
      _apply(shop, busy: false, screen: 'pay');
      unawaited(_prepareVpn());
    } catch (e) {
      busy = false;
      error = _err(e);
    }
    notifyListeners();
  }

  Future<void> pickAndUploadReceipt() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    busy = true;
    error = null;
    message = l10n.sendingReceipt;
    notifyListeners();
    try {
      final bytes = await file.readAsBytes();
      shop = await api.uploadReceipt(bytes, file.name);
      _apply(
        shop,
        busy: false,
        screen: 'order',
        message: l10n.receiptSent,
      );
      unawaited(_prepareVpn());
      unawaited(_poll());
    } catch (e) {
      busy = false;
      message = null;
      error = _err(e);
    }
    notifyListeners();
  }

  Future<void> login() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      shop = await api.login(loginCtrl.text.trim());
      _apply(shop, busy: false, screen: 'vpn', message: l10n.loggedIn);
      await maybeAutoConnect();
    } catch (e) {
      busy = false;
      error = _err(e);
    }
    notifyListeners();
  }

  void go(String s) {
    screen = s;
    notifyListeners();
  }

  Future<void> toggleVpn() async {
    error = null;
    final conf = _confFor();
    try {
      if (await vpn.isUp()) {
        await vpn.disconnect();
        vpnOn = false;
        _userOff = true;
        message = l10n.vpnOff;
        notifyListeners();
        return;
      }
      final payload = conf;
      if (payload == null || payload.trim().isEmpty) {
        error = l10n.buyPlanFirst;
        screen = 'home';
        notifyListeners();
        return;
      }
      connecting = true;
      notifyListeners();
      final prepared = await _prepareVpn();
      if (!prepared) {
        connecting = false;
        screen = 'vpn';
        message = l10n.allowVpn;
        notifyListeners();
        return;
      }
      await vpn.connect(payload);
      await _rememberConf(payload, shop.order?.id);
      connecting = false;
      vpnOn = true;
      _userOff = false;
      screen = 'vpn';
      message = l10n.vpnEnabled;
    } catch (e) {
      connecting = false;
      error = _err(e);
    }
    notifyListeners();
  }

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    for (var i = 0; i < 400; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        await _watch();
        if (vpnOn) break;
        final st = shop.order?.status;
        if (st == 'rejected' || st == 'disabled' || st == 'expired' || st == 'failed') break;
      } catch (_) {}
    }
    _polling = false;
  }

  Future<void> _watch() async {
    if (_watching || _api == null) return;
    _watching = true;
    try {
      shop = await api.state();
      _apply(shop);
      await _pullConfig();
      notifyListeners();
      await maybeAutoConnect();
    } catch (_) {
    } finally {
      _watching = false;
    }
  }

  Future<void> _pullConfig() async {
    final oid = shop.order?.id;
    final st = shop.order?.status;
    final have = (shop.config?.devices.isNotEmpty ?? false) &&
        (shop.config!.devices.first.conf.isNotEmpty);
    if (have) return;
    if (st != 'fulfilled' && shop.order?.ready != true) return;
    final cfg = await api.fetchConfig(oid: oid);
    if (cfg != null && cfg.devices.isNotEmpty) {
      shop = shop.copyWith(config: cfg);
    }
  }

  bool get protocolReady => _confFor()?.isNotEmpty == true;

  String? _confFor() {
    final devices = shop.config?.devices ?? const <VpnDevice>[];
    final device = devices.isEmpty ? null : devices.first;
    final fromShop = device?.conf.trim() ?? '';
    if (fromShop.isNotEmpty) return fromShop;
    if (_savedConf != null && _savedConf!.trim().isNotEmpty) return _savedConf;
    return null;
  }

  String? _bestConf() => _confFor();

  Future<bool> _prepareVpn() async {
    try {
      return await vpn.prepare();
    } catch (_) {
      return true;
    }
  }

  Future<void> _rememberConf(String conf, String? oid) async {
    _savedConf = conf;
    _armedOid = oid;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vpn_conf', conf);
      if (oid != null) await prefs.setString('vpn_oid', oid);
    } catch (_) {}
  }

  Future<bool> maybeAutoConnect() async {
    vpnOn = await vpn.isUp();
    if (vpnOn) {
      connecting = false;
      error = null;
      if (message == l10n.paidConnecting) message = null;
      return true;
    }
    final conf = _bestConf();
    final oid = shop.order?.id;
    final paid = shop.order?.ready == true || shop.order?.status == 'fulfilled';
    if (conf == null || conf.isEmpty) return false;
    if (_userOff && oid != null && oid == _armedOid) return false;
    if (!paid && conf != _savedConf) return false;
    connecting = true;
    message = l10n.paidConnecting;
    notifyListeners();
    try {
      final prepared = await _prepareVpn();
      if (!prepared) {
        connecting = false;
        message = l10n.paidTap;
        notifyListeners();
        return false;
      }
      await vpn.connect(conf);
      await _rememberConf(conf, oid);
      connecting = false;
      vpnOn = true;
      _userOff = false;
      message = l10n.vpnEnabled;
      notifyListeners();
      return true;
    } catch (e) {
      connecting = false;
      vpnOn = await vpn.isUp();
      if (vpnOn) {
        error = null;
        message = null;
      } else {
        error = _err(e);
      }
      notifyListeners();
      return vpnOn;
    }
  }

  void _apply(
    ShopState shop, {
    bool loading = false,
    bool busy = false,
    String? screen,
    String? message,
  }) {
    final prev = this.shop.order?.id;
    this.shop = shop;
    this.loading = loading;
    this.busy = busy;
    if (nameCtrl.text.isEmpty) nameCtrl.text = shop.order?.name ?? '';
    final st = shop.order?.status;
    if (shop.order?.id != null && shop.order!.id != prev) {
      _userOff = false;
    }
    if (screen != null) {
      this.screen = screen;
    } else if (_seenStatus != null && st != null && st != _seenStatus) {
      switch (st) {
        case 'fulfilled':
          this.screen = 'vpn';
        case 'pending':
          this.screen = 'pay';
        case 'awaiting_name':
          this.screen = 'order';
        case 'waiting_review':
        case 'paid':
          this.screen = 'order';
        default:
          break;
      }
    }
    _seenStatus = st;
    if (st == 'waiting_review' || st == 'paid' || st == 'fulfilled') {
      if (!_polling) unawaited(_poll());
    }
    if (message != null) {
      this.message = message;
    } else if (shop.flash != null) {
      this.message = shop.flash;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    nameCtrl.dispose();
    loginCtrl.dispose();
    super.dispose();
  }

  String _err(Object e) {
    final raw = e.toString();
    if (raw.contains('SocketException') ||
        raw.contains('ClientException') ||
        raw.contains('HandshakeException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('10057')) {
      return 'Нет связи с сервером. Проверьте интернет и нажмите «Обновить».';
    }
    return raw.replaceFirst('Exception: ', '');
  }
}
