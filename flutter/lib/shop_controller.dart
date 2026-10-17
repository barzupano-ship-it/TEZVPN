import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'features/vpn/application/subscription_pricing.dart';
import 'models.dart';
import 'shop_api.dart';
import 'features/vpn/application/tunnel_options.dart';
import 'vpn_channel.dart';
import 'l10n.dart';

class ShopController extends ChangeNotifier {
  ShopApi? _api;
  final vpn = VpnChannel();
  L10n l10n = L10n('ru');

  bool loading = true;
  bool busy = false;
  bool connecting = false;
  bool disconnecting = false;
  bool vpnOn = false;
  ShopState shop = const ShopState();
  String? error;
  String? message;
  final nameCtrl = TextEditingController();
  final regLoginCtrl = TextEditingController();
  final regPassCtrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();
  final passLoginCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  static final _loginRe = RegExp(r'^[a-z0-9_]{3,24}$');
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phoneRe = RegExp(r'^\+?[0-9][0-9\s\-()]{7,}$');
  String screen = 'welcome';
  bool registrationOpen = false;
  bool registering = true;
  BillingPeriod billingPeriod = BillingPeriod.oneMonth;
  String selectedSubscriptionPlan = 'premium';
  bool subscriptionAutoRenew = true;
  bool _polling = false;
  bool _watching = false;
  bool _userOff = false;
  String? _armedOid;
  String? _savedConf;
  String protocol = 'awg';
  bool netShield = false;
  bool killSwitchOn = false;
  bool vpnAccelerator = false;
  final excludedApps = <String>{};
  String? _seenStatus;
  Timer? _tick;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    l10n = L10n(prefs.getString('lang') == 'en' ? 'en' : 'ru');
    _savedConf = prefs.getString('vpn_conf');
    protocol = 'awg';
    netShield = prefs.getBool('opt_netshield') ?? false;
    killSwitchOn = prefs.getBool('opt_kill') ?? false;
    vpnAccelerator = prefs.getBool('opt_accel') ?? false;
    excludedApps
      ..clear()
      ..addAll((prefs.getString('opt_excluded') ?? '').split(',').where((item) => item.isNotEmpty));
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
    notifyListeners();
    unawaited(_persistLang());
  }

  Future<void> _persistLang() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      await prefs.setString('lang', l10n.code);
    } catch (_) {}
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
      if (screen == 'welcome' && (shop.account?.login ?? '').isNotEmpty) {
        screen = _confFor()?.isNotEmpty == true ? 'vpn' : 'home';
      }
      await maybeAutoConnect();
    } catch (e) {
      loading = false;
      error = _err(e);
    }
    notifyListeners();
  }

  void setBillingPeriod(BillingPeriod period) {
    if (billingPeriod == period) return;
    billingPeriod = period;
    notifyListeners();
  }

  void setSubscriptionAutoRenew(bool value) {
    subscriptionAutoRenew = value;
    notifyListeners();
  }

  /// Selects a plan for the current period. A paid plan with a shop product
  /// opens the existing order flow. Free does not start a purchase.
  Future<void> chooseSubscriptionPlan(String planId) async {
    selectedSubscriptionPlan = planId;
    notifyListeners();
    final spec = SubscriptionPricing.find(planId);
    if (spec == null || spec.free) return;
    final offer = SubscriptionPricing.resolve(spec, billingPeriod, shop.plans);
    final product = offer?.shopPlanId ?? '';
    if (product.isEmpty) return;
    await buy(product);
  }

  Future<void> buy(String planId) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await api.startOrder(planId);
      shop = await api.state();
      _apply(shop, busy: false, screen: 'order');
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

  String? _accountError(String login, String password, {String? again}) {
    if (!_loginRe.hasMatch(login)) return l10n.loginRules;
    if (password.length < 8) return l10n.passwordRules;
    if (again != null && password != again) return l10n.passwordMismatch;
    return null;
  }

  Future<void> register() async {
    final login = regLoginCtrl.text.trim().toLowerCase();
    final password = regPassCtrl.text;
    final problem = _accountError(login, password, again: regPass2Ctrl.text);
    if (problem != null) {
      error = problem;
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      shop = await api.register(login, password);
      regPassCtrl.clear();
      regPass2Ctrl.clear();
      _apply(shop, busy: false, screen: 'account', message: l10n.registered);
    } catch (e) {
      busy = false;
      error = _err(e);
    }
    notifyListeners();
  }

  Future<void> loginWithPassword() async {
    await signInWithIdentifier(passLoginCtrl.text, passCtrl.text, fromAccount: true);
  }

  String? _identifierError(String raw, String password) {
    final id = raw.trim();
    final asLogin = id.toLowerCase();
    final ok = _emailRe.hasMatch(id) || _phoneRe.hasMatch(id) || _loginRe.hasMatch(asLogin);
    if (!ok) return 'Укажите почту или телефон.';
    if (password.length < 8) return l10n.passwordRules;
    return null;
  }

  /// Signs in through the existing shop login. Email and phone are sent to
  /// the server; a rejected identifier stays on this screen with the server error.
  Future<void> signInWithIdentifier(String raw, String password, {bool fromAccount = false}) async {
    final id = raw.trim();
    final problem = _identifierError(id, password);
    if (problem != null) {
      error = problem;
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      try {
        shop = await api.loginWithPassword(id, password);
      } catch (e) {
        final msg = _err(e);
        if (!msg.contains('Неверный')) rethrow;
        try {
          shop = await api.register(id, password);
        } catch (e2) {
          final created = _err(e2);
          throw Exception(created.contains('занят') ? 'Неверный логин или пароль.' : created);
        }
      }
      passCtrl.clear();
      await _pullConfig();
      _apply(
        shop,
        busy: false,
        screen: _confFor()?.isNotEmpty == true ? 'vpn' : 'home',
        message: l10n.loggedIn,
      );
      await maybeAutoConnect();
    } catch (e) {
      busy = false;
      error = _err(e);
      if (fromAccount) screen = 'account';
    }
    notifyListeners();
  }

  /// Opens Telegram and waits until the bot confirms this device.
  /// The app never accepts a Telegram id from the button itself.
  Future<void> signInWithTelegram() async {
    busy = true;
    error = null;
    message = 'Откройте Telegram и подтвердите вход.';
    notifyListeners();
    try {
      final start = await api.startTelegramLogin();
      final opened = await launchUrl(Uri.parse(start.url), mode: LaunchMode.externalApplication);
      if (!opened) {
        throw Exception('Не удалось открыть Telegram.');
      }
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final status = await api.pollTelegramLogin(start.challenge);
        if (status == 'confirmed') {
          shop = await api.state();
          message = null;
          _apply(shop, busy: false, screen: 'vpn', message: l10n.loggedIn);
          await maybeAutoConnect();
          notifyListeners();
          return;
        }
      }
      throw Exception('Время входа истекло. Нажмите Telegram ещё раз.');
    } catch (e) {
      busy = false;
      message = null;
      error = _err(e);
    }
    notifyListeners();
  }

  void go(String s) {
    if (s == 'auth') {
      openRegistration();
      return;
    }
    screen = s;
    if (s != 'welcome') registrationOpen = false;
    notifyListeners();
  }

  void openRegistration({bool create = true}) {
    screen = 'welcome';
    registrationOpen = true;
    registering = create;
    error = null;
    notifyListeners();
  }

  void closeRegistration() {
    registrationOpen = false;
    error = null;
    notifyListeners();
  }

  bool get hasProAccess {
    bool paid(Order order) => order.status == 'fulfilled' || order.ready;
    bool pro(Order order) {
      final id = order.plan.toLowerCase();
      final title = order.title.toLowerCase();
      if (id.startsWith('std') || title.contains('standard')) return false;
      if (id.startsWith('prem') || title.contains('vip') || title.contains('premium') || title.contains('plus')) return true;
      return id == '1m1' || id == '3m2' || id == '6m4' || id == '12m4';
    }

    final orders = <Order>[
      if (shop.order != null) shop.order!,
      ...shop.orders,
    ];
    return orders.any((order) => paid(order) && pro(order));
  }

  void openProFeature(String page) {
    if (!hasProAccess) {
      message = l10n.proRequired;
      screen = 'home';
      notifyListeners();
      return;
    }
    go(page);
  }

  Future<void> setNetShield(bool value) async {
    netShield = value;
    await _saveTunnelOptions();
    await _reapplyTunnel();
  }

  Future<void> setVpnAccelerator(bool value) async {
    vpnAccelerator = value;
    await _saveTunnelOptions();
    await _reapplyTunnel();
  }

  Future<void> setKillSwitchEnabled(bool value) async {
    killSwitchOn = value;
    await _saveTunnelOptions();
    try {
      await vpn.setKillSwitch(value);
    } catch (e) {
      error = _err(e);
    }
    await _reapplyTunnel();
  }

  Future<void> toggleExcludedApp(String package, bool exclude) async {
    if (exclude) {
      excludedApps.add(package);
    } else {
      excludedApps.remove(package);
    }
    await _saveTunnelOptions();
    await _reapplyTunnel();
  }

  Future<String> createDeviceCode() => api.startDeviceLogin().then((start) => start.code);

  Future<List<SupportTicket>> loadSupport() {
    final current = _api;
    if (current == null) return Future.value(const []);
    return current.supportTickets();
  }

  Future<void> sendSupport(String text) async {
    final current = _api;
    if (current == null) return;
    await current.sendSupport(text);
  }

  Future<void> sendSupportFile(List<int> bytes, String filename, String text) async {
    final current = _api;
    if (current == null) return;
    await current.sendSupportFile(bytes, filename, text);
  }

  Future<Uint8List> loadSupportFile(int id) {
    final current = _api;
    if (current == null) return Future.error(Exception('Сначала войдите почтой или телефоном.'));
    return current.supportFile(id);
  }

  Future<void> claimDeviceCode(String code) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      shop = await api.claimDeviceLogin(code);
      await _pullConfig();
      _apply(
        shop,
        busy: false,
        screen: _confFor()?.isNotEmpty == true ? 'vpn' : 'home',
        message: l10n.loggedIn,
      );
      await maybeAutoConnect();
    } catch (e) {
      busy = false;
      error = _err(e);
    }
    notifyListeners();
  }

  Future<void> _saveTunnelOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      await prefs.setBool('opt_netshield', netShield);
      await prefs.setBool('opt_kill', killSwitchOn);
      await prefs.setBool('opt_accel', vpnAccelerator);
      await prefs.setString('opt_excluded', excludedApps.join(','));
    } catch (_) {}
  }

  Future<void> _reapplyTunnel() async {
    notifyListeners();
    if (!await vpn.isUp()) return;
    final conf = _confFor();
    if (conf == null || conf.trim().isEmpty) return;
    connecting = true;
    notifyListeners();
    try {
      await vpn.disconnect();
      await vpn.setKillSwitch(killSwitchOn);
      await vpn.connect(applyTunnelOptions(
        conf,
        netShield: netShield,
        accelerator: vpnAccelerator,
        excludedApps: excludedApps,
      ));
      vpnOn = true;
      message = l10n.vpnEnabled;
    } catch (e) {
      error = _err(e);
    } finally {
      connecting = false;
      notifyListeners();
    }
  }

  void selectProtocol(String id) {
    if (id != 'awg') {
      error = l10n.protocolMissing;
      notifyListeners();
      return;
    }
    protocol = 'awg';
    if (_api != null) _api!.protocol = 'awg';
    message = vpnOn ? l10n.protocolActive : null;
    notifyListeners();
  }

  Future<void> registerWithIdentifier(String raw, String password, String again) async {
    final id = raw.trim();
    final problem = _identifierError(id, password);
    if (problem != null) {
      error = problem;
      notifyListeners();
      return;
    }
    if (password != again) {
      error = l10n.passwordMismatch;
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      shop = await api.register(id, password);
      registrationOpen = false;
      _apply(shop, busy: false, screen: 'home', message: l10n.registered);
      await maybeAutoConnect();
    } catch (e) {
      busy = false;
      error = _err(e);
    }
    notifyListeners();
  }

  Future<void> signInExisting(String raw, String password) async {
    final id = raw.trim();
    final problem = _identifierError(id, password);
    if (problem != null) {
      error = problem;
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      shop = await api.loginWithPassword(id, password);
      registrationOpen = false;
      await _pullConfig();
      _apply(
        shop,
        busy: false,
        screen: _confFor()?.isNotEmpty == true ? 'vpn' : 'home',
        message: l10n.loggedIn,
      );
      await maybeAutoConnect();
    } catch (e) {
      busy = false;
      error = _err(e);
    }
    notifyListeners();
  }

  Future<void> toggleVpn() async {
    error = null;
    final conf = _confFor();
    try {
      if (await vpn.isUp()) {
        disconnecting = true;
        notifyListeners();
        await vpn.disconnect();
        vpnOn = false;
        disconnecting = false;
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
      try {
        await vpn.setKillSwitch(killSwitchOn);
      } catch (_) {}
      await vpn.connect(applyTunnelOptions(
        payload,
        netShield: netShield,
        accelerator: vpnAccelerator,
        excludedApps: excludedApps,
      ));
      await _rememberConf(payload, shop.order?.id);
      connecting = false;
      vpnOn = true;
      _userOff = false;
      screen = 'vpn';
      message = l10n.vpnEnabled;
    } catch (e) {
      connecting = false;
      disconnecting = false;
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
    regLoginCtrl.dispose();
    regPassCtrl.dispose();
    regPass2Ctrl.dispose();
    passLoginCtrl.dispose();
    passCtrl.dispose();
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
