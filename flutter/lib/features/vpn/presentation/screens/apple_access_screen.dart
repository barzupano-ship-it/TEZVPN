import 'package:flutter/material.dart';

import '../../../../shop_controller.dart';

/// App Store build replacement for plans, order and payment screens:
/// shows the access status and sends an access request without a receipt.
class AppleAccessScreen extends StatelessWidget {
  const AppleAccessScreen({super.key, required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    final t = shop.l10n;
    final status = shop.shop.order?.status ?? '';
    final signedIn = (shop.shop.account?.login ?? '').isNotEmpty;
    final active = shop.hasPaidAccess;
    final waiting = !active && (status == 'waiting_review' || status == 'paid');

    final String text;
    if (active) {
      text = t.accessActive('');
    } else if (waiting) {
      text = t.accessRequested;
    } else if (status == 'rejected') {
      text = t.accessRejected;
    } else if (status == 'expired') {
      text = t.subscriptionExpired;
    } else if (status == 'disabled') {
      text = t.disabled;
    } else {
      text = signedIn ? t.accessNone : t.accessSignIn;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => shop.go('vpn'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 18),
              tooltip: t.pick('Назад', 'Back'),
            ),
            Expanded(
              child: Text(
                t.accessTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: active ? const Color(0xFF2F6FED) : const Color(0xFFD5E4F7)),
          ),
          child: Column(
            children: [
              Icon(
                active
                    ? Icons.verified_user_rounded
                    : waiting
                        ? Icons.hourglass_top_rounded
                        : Icons.shield_outlined,
                color: const Color(0xFF2F6FED),
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF1C1B22), fontSize: 15, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (active)
          _Primary(label: t.openVpn, onPressed: () => shop.go('vpn'))
        else if (waiting)
          OutlinedButton(
            onPressed: shop.busy ? null : shop.refresh,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(t.refreshStatus),
          )
        else if (status != 'disabled')
          _Primary(
            label: signedIn ? t.accessRequest : t.signIn,
            onPressed: shop.busy
                ? null
                : signedIn
                    ? shop.requestAccess
                    : () => shop.openRegistration(create: false),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => shop.go('support'),
          icon: const Icon(Icons.support_agent_rounded),
          label: Text(t.settingsHelp),
        ),
      ],
    );
  }
}

class _Primary extends StatelessWidget {
  const _Primary({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2F6FED),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
