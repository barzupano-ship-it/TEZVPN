import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n.dart';
import '../../../../shop_controller.dart';
import '../widgets/vpn_settings_tile.dart';

class VpnSettingsScreen extends StatelessWidget {
  const VpnSettingsScreen({super.key, required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    final t = shop.l10n;
    final account = _AccountText(shop.shop.account?.login ?? '', t);
    final on = shop.l10n.pick('Вкл', 'On');
    final off = shop.l10n.settingsOff;
    final protocol = shop.protocol == 'awg' ? 'AmneziaWG' : shop.protocol;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        children: [
          _SectionLabel(t.settingsAccount),
          VpnSettingsTile(
            icon: _Avatar(letter: account.letter),
            title: account.title,
            subtitle: account.subtitle,
            trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF929399), size: 20),
            onTap: account.guest ? shop.openRegistration : () => shop.go('account'),
          ),
          VpnSettingsTile(
            icon: const SettingsIcon(icon: Icons.qr_code_2_rounded),
            title: t.settingsOtherDevice,
            onTap: () => shop.go('device-signin'),
          ),
          const SizedBox(height: 10),
          _SectionLabel(t.settingsFeatures),
          VpnSettingsTile(
            icon: const SettingsIcon(icon: Icons.gpp_maybe_outlined),
            title: t.settingsKill,
            subtitle: shop.killSwitchOn ? on : off,
            onTap: () => shop.go('killswitch'),
          ),
          const SizedBox(height: 10),
          _SectionLabel(t.settingsConnection),
          VpnSettingsTile(
            icon: const SettingsIcon(icon: Icons.hub_outlined),
            title: t.settingsProtocol,
            subtitle: protocol,
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF929399), size: 22),
            onTap: () => shop.go('protocol'),
          ),
          const SizedBox(height: 10),
          _SectionLabel(t.settingsGeneral),
          VpnSettingsTile(
            icon: const SettingsIcon(icon: Icons.translate_rounded),
            title: t.settingsLanguage,
            subtitle: shop.l10n.en ? 'English' : 'Русский',
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF929399), size: 22),
            onTap: () => shop.go('language'),
          ),
          VpnSettingsTile(
            icon: const SettingsIcon(icon: Icons.help_outline_rounded),
            title: t.settingsHelp,
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF929399), size: 22),
            onTap: () => shop.go('support'),
          ),
        ],
      ),
    );
  }
}

class _AccountText {
  _AccountText(String login, L10n l10n) {
    final value = login.trim();
    guest = value.isEmpty;
    if (guest) {
      title = l10n.settingsSignIn;
      subtitle = l10n.settingsEmailOrPhone;
      letter = '';
      return;
    }
    if (value.startsWith('tg:')) {
      title = 'Telegram';
      subtitle = 'Telegram';
      letter = 'T';
      return;
    }
    if (value.contains('@')) {
      title = value;
      subtitle = value.split('@').first;
      letter = subtitle.isEmpty ? '' : subtitle[0].toUpperCase();
      return;
    }
    title = value;
    subtitle = l10n.settingsPhone;
    letter = value.isEmpty ? '' : value[0];
  }

  late final bool guest;
  late final String title;
  late final String subtitle;
  late final String letter;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFFE3EEFF), shape: BoxShape.circle),
      child: letter.isEmpty
          ? const Icon(Icons.person_rounded, size: 18, color: Color(0xFF2F5F9A))
          : Text(
              letter,
              style: const TextStyle(color: Color(0xFF2F5F9A), fontSize: 14, fontWeight: FontWeight.w700),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF929399),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
