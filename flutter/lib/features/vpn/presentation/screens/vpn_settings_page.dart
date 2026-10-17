import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../../../config.dart';
import '../../../../shop_api.dart';
import '../../../../shop_controller.dart';

/// Detail pages for settings. Unsupported protections stay off.
class VpnSettingsPage extends StatelessWidget {
  const VpnSettingsPage({super.key, required this.shop, required this.page});

  final ShopController shop;
  final String page;

  @override
  Widget build(BuildContext context) {
    if (page == 'split') return _SplitApps(shop: shop);
    if (page == 'device-signin') return _DeviceSignIn(shop: shop);
    if (page == 'support') return _SupportDesk(shop: shop);
    final t = shop.l10n;
    final content = switch (page) {
      'netshield' => _SwitchPage(
          title: 'NetShield',
          body: t.pick(
            'Фильтр DNS включён: рекламные домены идут через AdGuard DNS. Если VPN уже включён, туннель переподключается.',
            'DNS filter: ad domains use AdGuard DNS. If VPN is already on, the tunnel reconnects.',
          ),
          value: shop.netShield,
          onChanged: shop.setNetShield,
          error: shop.error,
        ),
      'killswitch' => _SwitchPage(
          title: t.settingsKill,
          body: t.pick(
            'Когда VPN обрывается, трафик блокируется, пока туннель не поднимется снова.',
            'When the VPN drops, traffic stays blocked until the tunnel is up again.',
          ),
          value: shop.killSwitchOn,
          onChanged: shop.setKillSwitchEnabled,
          error: shop.error,
        ),
      'accelerator' => _SwitchPage(
          title: t.settingsAccelerator,
          body: t.pick(
            'DNS 1.1.1.1 вместо DNS сервера. Если NetShield включён, используется его фильтр.',
            'Uses DNS 1.1.1.1. If NetShield is on, its filter is used instead.',
          ),
          value: shop.vpnAccelerator,
          onChanged: shop.setVpnAccelerator,
          error: shop.error,
        ),
      'advanced' => _Advanced(shop: shop),
      'protocol' => _Protocol(shop: shop),
      'language' => _Language(shop: shop),
      _ => _Copy(title: t.settingsPrivacy, body: t.privacyDraft),
    };
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => shop.go('settings'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 18),
            ),
          ),
          content,
        ],
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(body, style: const TextStyle(color: Color(0xFF929399), fontSize: 14, height: 1.4)),
      ],
    );
  }
}

class _Protocol extends StatelessWidget {
  const _Protocol({required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    final selected = shop.protocol == 'awg';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shop.l10n.settingsProtocol, style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          shop.l10n.protocolBody,
          style: TextStyle(color: Color(0xFF929399), fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 12),
        Material(
          color: const Color(0xFFEEF4FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD5E4F7)),
          ),
          child: ListTile(
            onTap: () => shop.selectProtocol('awg'),
            title: const Text('AmneziaWG', style: TextStyle(color: Color(0xFF1C1B22), fontWeight: FontWeight.w600)),
            trailing: Icon(
              selected ? Icons.check_rounded : Icons.circle_outlined,
              color: const Color(0xFF3B82F6),
            ),
          ),
        ),
      ],
    );
  }
}

class _Language extends StatelessWidget {
  const _Language({required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shop.l10n.settingsLanguage, style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _LangRow(label: 'Русский', selected: !shop.l10n.en, onTap: () => shop.setLang('ru')),
        const SizedBox(height: 8),
        _LangRow(label: 'English', selected: shop.l10n.en, onTap: () => shop.setLang('en')),
      ],
    );
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF4FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD5E4F7)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(label, style: const TextStyle(color: Color(0xFF1C1B22), fontWeight: FontWeight.w600)),
        trailing: Icon(
          selected ? Icons.check_rounded : Icons.circle_outlined,
          color: selected ? const Color(0xFF3B82F6) : const Color(0xFF929399),
        ),
      ),
    );
  }
}

class _SwitchPage extends StatelessWidget {
  const _SwitchPage({
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(body, style: const TextStyle(color: Color(0xFF929399), fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        Material(
          color: const Color(0xFFEEF4FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD5E4F7)),
          ),
          child: SwitchListTile(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF3B82F6),
            title: Text(
              value ? 'Вкл' : 'Выкл',
              style: const TextStyle(color: Color(0xFF1C1B22), fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: Color(0xFFC62828))),
        ],
      ],
    );
  }
}

class _Advanced extends StatelessWidget {
  const _Advanced({required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    final t = shop.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.settingsAdvanced, style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(t.advancedBody, style: const TextStyle(color: Color(0xFF929399), fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        _LangRow(label: 'NetShield', selected: shop.netShield, onTap: () => shop.go('netshield')),
        const SizedBox(height: 8),
        _LangRow(label: t.settingsSplit, selected: shop.excludedApps.isNotEmpty, onTap: () => shop.go('split')),
        const SizedBox(height: 8),
        _LangRow(label: t.settingsKill, selected: shop.killSwitchOn, onTap: () => shop.go('killswitch')),
        const SizedBox(height: 8),
        _LangRow(label: t.settingsAccelerator, selected: shop.vpnAccelerator, onTap: () => shop.go('accelerator')),
        const SizedBox(height: 8),
        _LangRow(label: t.settingsProtocol, selected: true, onTap: () => shop.go('protocol')),
      ],
    );
  }
}

class _SplitApps extends StatefulWidget {
  const _SplitApps({required this.shop});

  final ShopController shop;

  @override
  State<_SplitApps> createState() => _SplitAppsState();
}

class _SplitAppsState extends State<_SplitApps> {
  List<({String package, String label})> _apps = const [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    widget.shop.vpn.launchableApps().then((apps) {
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => shop.go('settings'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              shop.l10n.settingsSplit,
              style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              shop.l10n.pick('Отмеченные приложения идут мимо VPN.', 'Checked apps bypass the VPN.'),
              style: const TextStyle(color: Color(0xFF929399), fontSize: 14),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _apps.length,
                  itemBuilder: (context, index) {
                    final app = _apps[index];
                    final excluded = shop.excludedApps.contains(app.package);
                    return CheckboxListTile(
                      value: excluded,
                      onChanged: (value) => shop.toggleExcludedApp(app.package, value == true),
                      activeColor: const Color(0xFF3B82F6),
                      title: Text(app.label, style: const TextStyle(color: Color(0xFF1A1C1E))),
                      subtitle: Text(app.package, style: const TextStyle(color: Color(0xFF929399), fontSize: 12)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DeviceSignIn extends StatefulWidget {
  const _DeviceSignIn({required this.shop});

  final ShopController shop;

  @override
  State<_DeviceSignIn> createState() => _DeviceSignInState();
}

class _DeviceSignInState extends State<_DeviceSignIn> {
  final _code = TextEditingController();
  String? _mine;
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final code = await widget.shop.createDeviceCode();
      if (mounted) setState(() => _mine = code);
    } catch (e) {
      widget.shop.error = '$e'.replaceFirst('Exception: ', '');
      widget.shop.notifyListeners();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final login = shop.shop.account?.login ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => shop.go('settings'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 18),
          ),
        ),
        Text(
          shop.l10n.settingsOtherDevice,
          style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (login.isEmpty)
          FilledButton(onPressed: shop.openRegistration, child: Text(shop.l10n.settingsSignIn))
        else ...[
          Text(login, style: const TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            shop.l10n.pick(
              'Кодов можно создать столько, сколько конфигов выдано. На другом телефоне введите код ниже.',
              'You can create as many codes as configs issued. Enter the code on the other phone.',
            ),
            style: const TextStyle(color: Color(0xFF929399), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: Text(shop.l10n.pick('Создать код', 'Create code')),
          ),
          if (_mine != null) ...[
            const SizedBox(height: 16),
            Text(
              _mine!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
          ],
        ],
        const SizedBox(height: 20),
        TextField(
          controller: _code,
          style: const TextStyle(color: Color(0xFF1A1C1E)),
          decoration: InputDecoration(
            labelText: shop.l10n.pick('Код с другого телефона', 'Code from the other phone'),
            labelStyle: const TextStyle(color: Color(0xFF929399)),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: shop.busy ? null : () => shop.claimDeviceCode(_code.text),
          child: Text(shop.l10n.loginButton),
        ),
        if (shop.error != null) ...[
          const SizedBox(height: 10),
          Text(shop.error!, style: const TextStyle(color: Color(0xFFC62828))),
        ],
      ],
    );
  }
}

class _ChatLine {
  const _ChatLine({
    required this.mine,
    required this.text,
    required this.unix,
    required this.read,
    this.fileName = '',
    this.fileMime = '',
    this.ticketId = 0,
  });

  final bool mine;
  final String text;
  final int unix;
  final bool read;
  final String fileName;
  final String fileMime;
  final int ticketId;

  bool get hasFile => fileName.isNotEmpty && ticketId > 0;
}

class _SupportDesk extends StatefulWidget {
  const _SupportDesk({required this.shop});

  final ShopController shop;

  @override
  State<_SupportDesk> createState() => _SupportDeskState();
}

class _SupportDeskState extends State<_SupportDesk> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<SupportTicket> _items = const [];
  var _loading = true;
  var _sending = false;
  var _pin = true;
  String? _error;
  Timer? _timer;
  Uint8List? _pendingBytes;
  String _pendingName = '';

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      if (mounted) setState(() {});
    });
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final gap = _scroll.position.maxScrollExtent - _scroll.offset;
      _pin = gap < 80;
    });
    final login = widget.shop.shop.account?.login ?? '';
    if (login.isEmpty) {
      _loading = false;
      return;
    }
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_sending) return;
      _load(quiet: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<_ChatLine> get _lines {
    final rows = _items.reversed.toList();
    final lines = <_ChatLine>[];
    for (final item in rows) {
      lines.add(_ChatLine(
        mine: true,
        text: item.body,
        unix: item.created,
        read: item.reply.isNotEmpty,
        fileName: item.fileName,
        fileMime: item.fileMime,
        ticketId: item.id,
      ));
      if (item.reply.isNotEmpty) {
        lines.add(_ChatLine(mine: false, text: item.reply, unix: item.replied, read: false));
      }
    }
    return lines;
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final items = await widget.shop.loadSupport();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        if (!quiet) _error = null;
      });
      _stick();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!quiet || _items.isEmpty) _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  void _stick() {
    if (!_pin) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    final bytes = _pendingBytes;
    final name = _pendingName;
    if (_sending) return;
    if (bytes == null && text.length < 4) {
      setState(() => _error = widget.shop.l10n.pick('Напишите сообщение.', 'Write a message.'));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _pin = true;
    });
    try {
      if (bytes != null) {
        await widget.shop.sendSupportFile(bytes, name, text);
      } else {
        await widget.shop.sendSupport(text);
      }
      _text.clear();
      _pendingBytes = null;
      _pendingName = '';
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openAttach() async {
    final shop = widget.shop;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: Color(0xFF2F6FED)),
              title: Text(shop.l10n.pick('Фото', 'Photo')),
              onTap: () => Navigator.pop(context, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded, color: Color(0xFF2F6FED)),
              title: Text(shop.l10n.pick('Файл', 'File')),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'photo') {
      await _pickPhoto();
    } else {
      await _pickFile();
    }
  }

  void _keepFile(String name, Uint8List bytes) {
    if (bytes.length > 20 * 1024 * 1024) {
      setState(() => _error = widget.shop.l10n.pick('Файл больше 20 МБ.', 'File is larger than 20 MB.'));
      return;
    }
    setState(() {
      _pendingBytes = bytes;
      _pendingName = name.trim().isEmpty ? 'file' : name.trim();
      _error = null;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null || !mounted) return;
      _keepFile(file.name, await file.readAsBytes());
    } catch (e) {
      if (mounted) setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pickFile() async {
    try {
      if (Platform.isWindows) {
        final picked = await _pickWindowsFile();
        if (picked == null || !mounted) return;
        _keepFile(picked.$1, picked.$2);
        return;
      }
      if (Platform.isAndroid) {
        final raw = await const MethodChannel('ru.tezvpn.app/vpn').invokeMethod<dynamic>('pickSupportFile');
        if (raw is! Map || !mounted) return;
        final name = '${raw['name'] ?? 'file'}';
        final data = raw['bytes'];
        final bytes = data is Uint8List ? data : (data is List ? Uint8List.fromList(data.cast<int>()) : null);
        if (bytes == null) return;
        _keepFile(name, bytes);
        return;
      }
      if (mounted) {
        setState(() => _error = widget.shop.l10n.pick('На этом устройстве выберите фото.', 'On this device, choose a photo.'));
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final user = shop.shop.meta.support.isEmpty ? ShopConfig.support : shop.shop.meta.support;
    final login = shop.shop.account?.login ?? '';
    final lines = _lines;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Column(
        children: [
          _ChatHeader(
            title: shop.l10n.pick('Поддержка', 'Support'),
            subtitle: ShopConfig.appName,
            onBack: () => shop.go('settings'),
            onTelegram: () => launchUrl(Uri.parse('https://t.me/${user.replaceFirst('@', '')}')),
          ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF4F5F7),
              child: login.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2F5F9A), size: 36),
                            const SizedBox(height: 12),
                            Text(
                              shop.l10n.pick('Войдите, чтобы написать в поддержку.', 'Sign in to message support.'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF6E6A78)),
                            ),
                            const SizedBox(height: 14),
                            FilledButton(onPressed: shop.openRegistration, child: Text(shop.l10n.settingsSignIn)),
                          ],
                        ),
                      ),
                    )
                  : _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F6FED)))
                      : lines.isEmpty
                          ? Center(
                              child: Text(
                                shop.l10n.pick('Напишите сообщение', 'Write a message'),
                                style: const TextStyle(color: Color(0xFF6E6A78), fontSize: 15),
                              ),
                            )
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                              itemCount: lines.length,
                              itemBuilder: (context, index) {
                                final line = lines[index];
                                final previous = index == 0 ? null : lines[index - 1];
                                final showDay = previous == null || !_sameDay(previous.unix, line.unix);
                                return Column(
                                  children: [
                                    if (showDay && line.unix > 0) _DayChip(label: _dayLabel(line.unix, shop.l10n.en)),
                                    _Bubble(
                                      line: line,
                                      supportName: shop.l10n.pick('Поддержка', 'Support'),
                                      shop: shop,
                                    ),
                                  ],
                                );
                              },
                            ),
            ),
          ),
          if (login.isNotEmpty)
            _Composer(
              controller: _text,
              sending: _sending,
              error: _error,
              hint: shop.l10n.pick('Сообщение', 'Message'),
              pendingName: _pendingName,
              onAttach: _sending ? null : _openAttach,
              onClear: _sending ? null : () => setState(() {
                _pendingBytes = null;
                _pendingName = '';
              }),
              onSend: _sending || (_text.text.trim().length < 4 && _pendingBytes == null) ? null : _send,
            ),
        ],
      ),
    );
  }
}

bool _sameDay(int a, int b) {
  if (a <= 0 || b <= 0) return true;
  final left = DateTime.fromMillisecondsSinceEpoch(a * 1000);
  final right = DateTime.fromMillisecondsSinceEpoch(b * 1000);
  return left.year == right.year && left.month == right.month && left.day == right.day;
}

String _dayLabel(int unix, bool en) {
  final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  if (day == today) return en ? 'Today' : 'Сегодня';
  if (day == today.subtract(const Duration(days: 1))) return en ? 'Yesterday' : 'Вчера';
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  return '$dd.$mm.${dt.year}';
}

String _clock(int unix) {
  if (unix <= 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onTelegram,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onTelegram;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFD5E4F7))),
      ),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 18),
            ),
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE3EEFF),
              child: Icon(Icons.support_agent_rounded, color: Color(0xFF2F5F9A), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF6E6A78), fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Telegram',
              onPressed: onTelegram,
              icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF2F5F9A)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xFFE3EEFF), borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(label, style: const TextStyle(color: Color(0xFF2F5F9A), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line, required this.supportName, required this.shop});

  final _ChatLine line;
  final String supportName;
  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    final mine = line.mine;
    final time = _clock(line.unix);
    final hideText = line.hasFile && (line.text.trim().isEmpty || line.text.trim() == line.fileName);
    final ink = mine ? Colors.white : const Color(0xFF1C1B22);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF2F6FED) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 6),
            bottomRight: Radius.circular(mine ? 6 : 18),
          ),
          border: mine ? null : Border.all(color: const Color(0xFFD5E4F7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(supportName, style: const TextStyle(color: Color(0xFF2F5F9A), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            if (line.hasFile) ...[
              if (line.fileMime.startsWith('image/'))
                _SupportImage(shop: shop, ticketId: line.ticketId, light: mine)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file_outlined, size: 18, color: ink),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(line.fileName, style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              if (!hideText) const SizedBox(height: 6),
            ],
            if (!hideText)
              Text(line.text, style: TextStyle(color: ink, fontSize: 15, height: 1.3)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (time.isNotEmpty)
                  Text(time, style: TextStyle(color: mine ? const Color(0xE6FFFFFF) : const Color(0xFF6E6A78), fontSize: 11)),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(line.read ? Icons.done_all_rounded : Icons.done_rounded, size: 14, color: const Color(0xE6FFFFFF)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportImage extends StatefulWidget {
  const _SupportImage({required this.shop, required this.ticketId, required this.light});

  final ShopController shop;
  final int ticketId;
  final bool light;

  @override
  State<_SupportImage> createState() => _SupportImageState();
}

class _SupportImageState extends State<_SupportImage> {
  Uint8List? _bytes;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.shop.loadSupportFile(widget.ticketId);
      if (!mounted) return;
      setState(() => _bytes = bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.light ? Colors.white : const Color(0xFF1C1B22);
    if (_failed) return Icon(Icons.broken_image_outlined, color: ink);
    final bytes = _bytes;
    if (bytes == null) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: ink),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        bytes,
        width: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Icon(Icons.insert_drive_file_outlined, color: ink),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.error,
    required this.hint,
    required this.pendingName,
    required this.onAttach,
    required this.onClear,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final String? error;
  final String hint;
  final String pendingName;
  final VoidCallback? onAttach;
  final VoidCallback? onClear;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD5E4F7))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(error!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
                ),
              ),
            if (pendingName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 18, color: Color(0xFF2F6FED)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pendingName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF1C1B22), fontSize: 13),
                      ),
                    ),
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF6E6A78)),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onAttach,
                  tooltip: 'Файл',
                  icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF2F6FED)),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 1000,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend?.call(),
                    style: const TextStyle(color: Color(0xFF1C1B22), fontSize: 15),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: Color(0xFF6E6A78)),
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(color: Color(0xFF2F6FED)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: onSend == null ? const Color(0xFFD5E4F7) : const Color(0xFF2F6FED),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSend,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.send_rounded, color: onSend == null ? const Color(0xFF6E6A78) : Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<(String, Uint8List)?> _pickWindowsFile() async {
  const script = r'''
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Filter = "All files (*.*)|*.*"
$dialog.Multiselect = $false
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  [Console]::Out.WriteLine($dialog.FileName)
}
''';
  final result = await Process.run('powershell.exe', ['-NoProfile', '-STA', '-Command', script]);
  final lines = '${result.stdout}'.split(RegExp(r'\r?\n')).map((line) => line.trim()).where((line) => line.isNotEmpty);
  for (final line in lines) {
    final file = File(line);
    if (file.existsSync()) return (p.basename(line), await file.readAsBytes());
  }
  return null;
}
