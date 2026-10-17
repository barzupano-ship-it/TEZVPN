import 'package:flutter/material.dart';

import 'pro_badge.dart';

class VpnSettingsTile extends StatelessWidget {
  const VpnSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.pro = false,
    this.onTap,
    this.enabled = true,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool pro;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFEEF4FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD5E4F7)),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0x223B82F6),
          highlightColor: const Color(0x143B82F6),
          child: AnimatedOpacity(
            duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
            opacity: enabled ? 1 : 0.45,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1C1B22),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6E6A78),
                                fontSize: 12,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (pro) ...[
                      const SizedBox(width: 8),
                      const ProBadge(),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(width: 6),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key, required this.icon, this.color = const Color(0xFF2F5F9A)});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE3EEFF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
