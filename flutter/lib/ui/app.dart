import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../features/authentication/presentation/screens/legal_placeholder_screen.dart';
import '../features/authentication/presentation/screens/welcome_screen.dart';
import '../features/vpn/application/vpn_home_controller.dart';
import '../features/vpn/presentation/screens/servers_screen.dart';
import '../features/vpn/presentation/screens/subscription_screen.dart';
import '../features/vpn/presentation/screens/vpn_home_screen.dart';
import '../features/vpn/presentation/screens/vpn_settings_page.dart';
import '../features/vpn/presentation/screens/vpn_settings_screen.dart';
import '../features/vpn/presentation/widgets/vpn_bottom_navigation.dart';
import '../l10n.dart';
import '../models.dart';
import '../shop_controller.dart';

Color get gold => ShopConfig.gold;
Color get navy => ShopConfig.navy;
Color get card => ShopConfig.card;
const mute = Color(0xFF9DB0C3);

class TezHome extends StatefulWidget {
  const TezHome({super.key, required this.controller});
  final ShopController controller;

  @override
  State<TezHome> createState() => _TezHomeState();
}

class _TezHomeState extends State<TezHome> with WidgetsBindingObserver {
  ShopController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ui = controller;
        if (ui.screen == 'welcome' || ui.screen == 'auth' || ui.screen == 'terms' || ui.screen == 'privacy') {
          return Scaffold(
            backgroundColor: Colors.white,
            body: switch (ui.screen) {
              'auth' => WelcomeScreen(shop: ui),
              'terms' => LegalPlaceholderScreen(shop: ui, title: 'Условия использования'),
              'privacy' => LegalPlaceholderScreen(shop: ui, title: 'Политика конфиденциальности'),
              _ => WelcomeScreen(shop: ui),
            },
          );
        }
        final home = VpnHomeController(ui);
        final onHome = ui.screen == 'vpn';
        final settings = _settingsScreen(ui.screen);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
          child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, previousChildren) => currentChild ?? const SizedBox.shrink(),
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation);
                      return SlideTransition(position: slide, child: child);
                    },
                    child: KeyedSubtree(
                      key: ValueKey(ui.screen),
                      child: onHome
                      ? VpnHomeScreen(shop: ui)
                      : settings
                          ? _body(ui)
                          : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (ui.loading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Center(child: CircularProgressIndicator(color: Color(0xFF2F6FED))),
                              ),
                            if (ui.error != null && !ui.vpnOn)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(ui.error!, style: const TextStyle(color: Color(0xFFC62828))),
                              ),
                            if (ui.message != null && !ui.vpnOn)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(ui.message!, style: const TextStyle(color: Color(0xFF1E4FD8))),
                              ),
                            _body(ui),
                          ],
                        ),
                    ),
                  ),
                ),
                VpnBottomNavigation(index: home.tab, onSelected: home.openTab),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _body(ShopController ui) {
    switch (ui.screen) {
      case 'servers':
        return ServersScreen(shop: ui);
      case 'pay':
        return _Pay(ui: ui);
      case 'order':
        return _Order(ui: ui);
      case 'account':
        return _Account(ui: ui);
      case 'settings':
        return VpnSettingsScreen(shop: ui);
      case 'device-signin':
      case 'netshield':
      case 'split':
      case 'killswitch':
      case 'protocol':
      case 'accelerator':
      case 'advanced':
      case 'language':
      case 'privacy-note':
      case 'support':
        return VpnSettingsPage(shop: ui, page: ui.screen);
      default:
        return _Plans(ui: ui);
    }
  }
}

bool _settingsScreen(String screen) {
  switch (screen) {
    case 'settings':
    case 'device-signin':
    case 'netshield':
    case 'split':
    case 'killswitch':
    case 'protocol':
    case 'accelerator':
    case 'advanced':
    case 'language':
    case 'privacy-note':
    case 'support':
      return true;
    default:
      return false;
  }
}

class _LangSwitch extends StatelessWidget {
  const _LangSwitch({required this.ui});
  final ShopController ui;

  @override
  Widget build(BuildContext context) {
    final en = ui.l10n.en;
    return Row(
      children: [
        _chip('RU', !en, () => ui.setLang('ru')),
        const SizedBox(width: 4),
        _chip('EN', en, () => ui.setLang('en')),
      ],
    );
  }

  Widget _chip(String label, bool on, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? gold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? gold : mute),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: on ? const Color(0xFF111111) : mute,
          ),
        ),
      ),
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans({required this.ui});
  final ShopController ui;

  @override
  Widget build(BuildContext context) {
    return SubscriptionScreen(shop: ui);
  }
}

class _Order extends StatelessWidget {
  const _Order({required this.ui});
  final ShopController ui;

  @override
  Widget build(BuildContext context) {
    final t = ui.l10n;
    final o = ui.shop.order;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.order, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (o == null) ...[
          Text(t.noOrder, style: const TextStyle(color: mute)),
          FilledButton(onPressed: () => ui.go('home'), child: Text(t.toPlans)),
        ] else ...[
          StatusCard(order: o, l10n: t),
          const SizedBox(height: 12),
          if (o.status == 'awaiting_name') ...[
            TextField(
              controller: ui.nameCtrl,
              style: const TextStyle(color: Color(0xFF1A1C1E)),
              decoration: InputDecoration(
                labelText: t.yourName,
                labelStyle: const TextStyle(color: mute),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: mute)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold)),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: ui.submitName, child: Text(t.continueBtn)),
          ] else if (o.status == 'pending') ...[
            Text(t.payHint),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => ui.go('pay'), child: Text(t.requisites)),
            const SizedBox(height: 8),
            FilledButton(onPressed: ui.pickAndUploadReceipt, child: Text(t.uploadReceipt)),
          ] else if (o.status == 'waiting_review' || o.status == 'paid') ...[
            Text(t.waitAdmin),
            OutlinedButton(onPressed: ui.refresh, child: Text(t.refreshStatus)),
          ] else if (o.status == 'fulfilled') ...[
            Text(t.readyVpn, style: TextStyle(color: gold)),
            FilledButton(onPressed: () => ui.go('vpn'), child: Text(t.openVpn)),
          ] else if (o.status == 'rejected') ...[
            Text(t.rejected, style: const TextStyle(color: Color(0xFFC62828))),
            FilledButton(onPressed: () => ui.go('home'), child: Text(t.toPlans)),
          ] else if (o.status == 'disabled')
            Text(t.disabled, style: const TextStyle(color: Color(0xFFC62828))),
        ],
      ],
    );
  }
}

class _Pay extends StatelessWidget {
  const _Pay({required this.ui});
  final ShopController ui;

  @override
  Widget build(BuildContext context) {
    final t = ui.l10n;
    final pay = ui.shop.pay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.pay, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD5E4F7)),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Color(0xFF1C1B22)),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pay.payee.isNotEmpty) Text('${t.payee}: ${pay.payee}'),
              if (pay.alif.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Alif: ${pay.alif}')),
              if (pay.dc.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('DC: ${pay.dc}')),
              if (pay.payee.isEmpty && pay.alif.isEmpty)
                Text(t.loadingPay, style: const TextStyle(color: mute)),
            ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (pay.wechat)
          TextButton(
            onPressed: () => launchUrl(Uri.parse('${ShopConfig.shopUrl}/pay/wechat.png')),
            child: const Text('QR WeChat'),
          ),
        if (pay.alipay)
          TextButton(
            onPressed: () => launchUrl(Uri.parse('${ShopConfig.shopUrl}/pay/alipay.png')),
            child: const Text('QR Alipay'),
          ),
        FilledButton(onPressed: ui.pickAndUploadReceipt, child: Text(t.paidUpload)),
        const SizedBox(height: 8),
        SupportLink(
          user: ui.shop.meta.support.isEmpty ? ShopConfig.support : ui.shop.meta.support,
          label: t.support,
        ),
      ],
    );
  }
}

class _Account extends StatelessWidget {
  const _Account({required this.ui});
  final ShopController ui;

  @override
  Widget build(BuildContext context) {
    final t = ui.l10n;
    final login = ui.shop.account?.login ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(t.account, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            _LangSwitch(ui: ui),
          ],
        ),
        const SizedBox(height: 8),
        if (login.isNotEmpty) ...[
          Text(login.startsWith('tg:') ? t.signedInAs('Telegram') : t.signedInAs(login), style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
        ] else ...[
          Text(t.registerTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Почта или телефон и пароль — на первом экране.', style: const TextStyle(color: mute)),
          const SizedBox(height: 12),
          FilledButton(onPressed: ui.openRegistration, child: Text(t.createAccount)),
          const SizedBox(height: 20),
        ],
        if (ui.shop.order != null) ...[
          FilledButton(onPressed: () => ui.go('order'), child: Text(t.continueOrder)),
          const SizedBox(height: 16),
        ],
        Text(login.isEmpty ? t.signInTitle : t.otherAccount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _AccountField(controller: ui.passLoginCtrl, label: t.loginLabel),
        _AccountField(controller: ui.passCtrl, label: t.passwordLabel, secret: true),
        const SizedBox(height: 8),
        FilledButton(onPressed: ui.busy ? null : ui.loginWithPassword, child: Text(t.signIn)),
        const SizedBox(height: 16),
        SupportLink(
          user: ui.shop.meta.support.isEmpty ? ShopConfig.support : ui.shop.meta.support,
          label: t.support,
        ),
      ],
    );
  }
}

class _AccountField extends StatelessWidget {
  const _AccountField({required this.controller, required this.label, this.secret = false});
  final TextEditingController controller;
  final String label;
  final bool secret;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        obscureText: secret,
        autocorrect: false,
        enableSuggestions: !secret,
        style: const TextStyle(color: Color(0xFF1A1C1E)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: mute),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: mute)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold)),
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.order, required this.l10n});
  final Order order;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5E4F7)),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Color(0xFF1C1B22)),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.title.isEmpty ? order.plan : order.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(order.statusLabel.isEmpty ? order.status : order.statusLabel, style: TextStyle(color: gold)),
          if (order.amount.isNotEmpty) Text('${order.amount} смн', style: const TextStyle(color: mute)),
          if (order.name.isNotEmpty) Text(order.name, style: const TextStyle(color: mute)),
        ],
        ),
      ),
    );
  }
}

class SupportLink extends StatelessWidget {
  const SupportLink({super.key, required this.user, required this.label});
  final String user;
  final String label;

  @override
  Widget build(BuildContext context) {
    final u = user.replaceFirst('@', '');
    return TextButton.icon(
      onPressed: () => launchUrl(Uri.parse('https://t.me/$u')),
      icon: const Icon(Icons.help_outline),
      label: Text('$label @$u'),
    );
  }
}
