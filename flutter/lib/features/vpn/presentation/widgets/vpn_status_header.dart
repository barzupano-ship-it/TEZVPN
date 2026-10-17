import 'package:flutter/material.dart';

class VpnStatusHeader extends StatelessWidget {
  const VpnStatusHeader({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD5E4F7)),
            ),
            child: const Icon(Icons.shield_outlined, size: 15, color: Color(0xFF1A1C1E)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Connection',
                  style: TextStyle(color: Color(0xFF6E6A78), fontSize: 11, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF1A1C1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
