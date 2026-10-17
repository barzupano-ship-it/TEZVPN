import 'package:flutter/material.dart';

import '../../../../shop_controller.dart';

class ServersScreen extends StatelessWidget {
  const ServersScreen({super.key, required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    final devices = shop.shop.config?.devices ?? const [];
    final named = devices.where((d) => d.name.trim().isNotEmpty).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      children: [
        Text(
          shop.l10n.pick('Серверы', 'Servers'),
          style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          shop.l10n.pick(
            'Подключение идёт через сервер из вашего конфига.',
            'The connection uses the server from your config.',
          ),
          style: const TextStyle(color: Color(0xFF6E6A78)),
        ),
        const SizedBox(height: 16),
        if (named.isEmpty)
          Text(
            shop.l10n.pick(
              'Сервер появится после оплаты тарифа.',
              'A server appears after a plan is paid.',
            ),
            style: const TextStyle(color: Color(0xFF1A1C1E)),
          )
        else
          for (final device in named)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD5E4F7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, color: Color(0xFF2F6FED)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(device.name, style: const TextStyle(color: Color(0xFF1C1B22), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
