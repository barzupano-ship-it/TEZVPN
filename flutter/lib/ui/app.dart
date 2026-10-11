import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
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
        final t = ui.l10n;
        return Scaffold(
          backgroundColor: navy,
          bottomNavigationBar: NavigationBar(
            backgroundColor: card,
            indicatorColor: gold,
            selectedIndex: _tabIndex(ui.screen),
            onDestinationSelected: (i) {
              ui.go(['vpn', 'home', 'pay', 'account'][i]);
            },
            destinations: [
              NavigationDestination(icon: const Icon(Icons.power_settings_new), label: t.tabVpn),
              NavigationDestination(icon: const Icon(Icons.shopping_bag_outlined), label: t.tabPlans),
              NavigationDestination(icon: const Icon(Icons.credit_card_outlined), label: t.tabPay),
              NavigationDestination(icon: const Icon(Icons.person_outline), label: t.tabAccount),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.appTitle,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: gold),
                          ),
                          Text(t.tagline, style: const TextStyle(color: mute)),
                        ],
                      ),
                    ),
                    _LangSwitch(ui: ui),
                  ],
                ),
                const SizedBox(height: 12),
                if (ui.loading) Center(child: CircularProgressIndicator(color: gold)),
                if (ui.error != null && !ui.vpnOn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(ui.error!, style: const TextStyle(color: Color(0xFFFF8A80))),
                  ),
                if (ui.message != null && !ui.vpnOn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(ui.message!, style: TextStyle(color: gold)),
                  ),
                if (ui.busy || ui.connecting)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(color: gold, strokeWidth: 3),
                    ),
                  ),
                if (!ui.loading) _body(ui),
              ],
            ),
          ),
        );
      },
    );
  }

  int _tabIndex(String screen) {
    if (screen == 'order') return 1;
    const tabs = ['vpn', 'home', 'pay', 'account'];
    final i = tabs.indexOf(screen);
    return i < 0 ? 1 : i;
  }

  Widget _body(ShopController ui) {
    switch (ui.screen) {
      case 'vpn':
        return _Vpn(ui: ui);
      case 'pay':
        return _Pay(ui: ui);
      case 'order':
        return _Order(ui: ui);
      case 'account':
        return _Account(ui: ui);
      default:
        return _Plans(ui: ui);
    }
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

class _Vpn extends StatelessWidget {
  const _Vpn({required this.ui});
  final ShopController ui;

  @override
  Widget build(BuildContext context) {
    final t = ui.l10n;
    final devices = ui.shop.config?.devices ?? const <VpnDevice>[];
    final ready = ui.protocolReady;
    final order = ui.shop.order;
    String status;
    if (ui.connecting) {
      status = t.connecting;
    } else if (ui.vpnOn) {
      status = t.vpnOn;
    } else if (ready) {
      status = t.confReady;
    } else if (order?.status == 'waiting_review') {
      status = t.waitingReview;
    } else {
      status = t.buyFirst;
    }
    return Column(
      children: [
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: ui.vpnOn ? const Color(0xFF1FA971) : gold,
                foregroundColor: const Color(0xFF111111),
              ),
              onPressed: () {
                if (!ready && !ui.vpnOn) {
                  ui.go('home');
                } else {
                  ui.toggleVpn();
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.power_settings_new, size: 48),
                  Text(
                    ui.vpnOn
                        ? t.on
                        : ready
                            ? t.turnOn
                            : t.buy,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(status, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (ready)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(devices.first.name, style: const TextStyle(color: mute)),
          ),
        if (order != null && !ready) StatusCard(order: order, l10n: t),
      ],
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans({required this.ui});
  final ShopController ui;

  @override
  Widget build(BuildContext context) {
    final t = ui.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.plans, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (ui.shop.plans.isEmpty) ...[
          Text(t.plansFail, style: const TextStyle(color: mute)),
          FilledButton(onPressed: ui.refresh, child: Text(t.refresh)),
        ],
        for (final plan in ui.shop.plans) ...[
          _PlanCard(plan: plan, l10n: t, onBuy: () => ui.buy(plan.id)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.l10n, required this.onBuy});
  final Plan plan;
  final L10n l10n;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text(
            '${plan.tjs.toInt()} смн · ¥${plan.cny.toInt()} · ${plan.devices} ${l10n.devices}',
            style: TextStyle(color: gold),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onBuy,
            style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: const Color(0xFF111111)),
            child: Text(l10n.buyBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
              style: const TextStyle(color: Colors.white),
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
            Text(t.rejected, style: const TextStyle(color: Color(0xFFFF8A80))),
            FilledButton(onPressed: () => ui.go('home'), child: Text(t.toPlans)),
          ] else if (o.status == 'disabled')
            Text(t.disabled, style: const TextStyle(color: Color(0xFFFF8A80))),
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
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.account, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if ((ui.shop.account?.code ?? '').isNotEmpty) ...[
          Text(t.inCabinet, style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            ui.shop.account!.code,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
          Text(t.saveCode, style: const TextStyle(color: mute)),
          if (ui.shop.order != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: () => ui.go('order'), child: Text(t.continueOrder)),
          ],
          const SizedBox(height: 16),
          Text(t.otherPhone, style: const TextStyle(color: mute)),
        ] else ...[
          Text('${t.accessCode}: —'),
          Text(t.saveCode, style: const TextStyle(color: mute)),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: ui.loginCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: t.loginByCode,
            labelStyle: const TextStyle(color: mute),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: mute)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold)),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: ui.login, child: Text(t.signIn)),
        const SizedBox(height: 16),
        SupportLink(
          user: ui.shop.meta.support.isEmpty ? ShopConfig.support : ui.shop.meta.support,
          label: t.support,
        ),
      ],
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
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.title.isEmpty ? order.plan : order.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(order.statusLabel.isEmpty ? order.status : order.statusLabel, style: TextStyle(color: gold)),
          if (order.amount.isNotEmpty) Text('${order.amount} смн', style: const TextStyle(color: mute)),
          if (order.name.isNotEmpty) Text(order.name, style: const TextStyle(color: mute)),
        ],
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
