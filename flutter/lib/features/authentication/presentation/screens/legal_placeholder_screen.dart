import 'package:flutter/material.dart';

import '../../../../shop_controller.dart';

/// Placeholder only. This is not a finished legal document.
class LegalPlaceholderScreen extends StatelessWidget {
  const LegalPlaceholderScreen({super.key, required this.shop, required this.title});

  final ShopController shop;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => shop.go('welcome'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 18),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text(
            'Это заготовка страницы. Полный текст документа ещё не добавлен и не является юридическим документом.',
            style: TextStyle(color: Color(0xFF5C6166), fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
