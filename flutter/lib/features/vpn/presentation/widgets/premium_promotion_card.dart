import 'package:flutter/material.dart';

import 'crown_icon.dart';

class PremiumPromotionCard extends StatefulWidget {
  const PremiumPromotionCard({super.key, required this.onTap, required this.title});

  final VoidCallback onTap;
  final String title;

  @override
  State<PremiumPromotionCard> createState() => _PremiumPromotionCardState();
}

class _PremiumPromotionCardState extends State<PremiumPromotionCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD5E4F7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F6FED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const CrownIcon(size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(color: Color(0xFF1C1B22), fontSize: 14, height: 1.25, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF6E6A78)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
