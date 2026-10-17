import 'package:flutter/material.dart';

import '../../../../l10n.dart';
import '../../../../shop_controller.dart';
import '../../application/subscription_pricing.dart';
import '../widgets/crown_icon.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    final period = shop.billingPeriod;
    final currentProduct = shop.shop.order?.status == 'fulfilled' ? (shop.shop.order?.plan ?? '') : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => shop.go('vpn'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 18),
              tooltip: 'Назад',
            ),
            Expanded(
              child: Text(
                shop.l10n.plansTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 8),
        _PeriodSelector(
          selected: period,
          l10n: shop.l10n,
          onSelected: shop.setBillingPeriod,
        ),
        const SizedBox(height: 16),
        for (final plan in SubscriptionPricing.plans) ...[
          _SubscriptionCard(
            plan: plan,
            period: period,
            offer: SubscriptionPricing.resolve(plan, period, shop.shop.plans),
            selected: shop.selectedSubscriptionPlan == plan.id,
            current: !plan.free &&
                currentProduct.isNotEmpty &&
                SubscriptionPricing.resolve(plan, period, shop.shop.plans)?.shopPlanId == currentProduct,
            autoRenew: shop.subscriptionAutoRenew,
            onAutoRenew: shop.setSubscriptionAutoRenew,
            onSelect: () => shop.chooseSubscriptionPlan(plan.id),
            l10n: shop.l10n,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected, required this.l10n});

  final BillingPeriod selected;
  final ValueChanged<BillingPeriod> onSelected;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final period in BillingPeriod.values)
            Expanded(
              child: _PeriodChip(
                period: period,
                label: l10n.periodMonths(period.months),
                selected: period == selected,
                onTap: () => onSelected(period),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.period, required this.label, required this.selected, required this.onTap});

  final BillingPeriod period;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = period.badge;
    return Semantics(
      button: true,
      selected: selected,
      label: badge == null ? label : '$label $badge',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2F6FED) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF3A3842),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1E4FD8) : const Color(0xFF2F6FED),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.plan,
    required this.period,
    required this.offer,
    required this.selected,
    required this.current,
    required this.autoRenew,
    required this.onAutoRenew,
    required this.onSelect,
    required this.l10n,
  });

  final SubscriptionPlanSpec plan;
  final BillingPeriod period;
  final ResolvedOffer? offer;
  final bool selected;
  final bool current;
  final bool autoRenew;
  final ValueChanged<bool> onAutoRenew;
  final VoidCallback onSelect;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final somoni = offer?.amountSomoni ?? 0;
    final yuan = offer?.amountYuan ?? 0;
    final border = current
        ? const Color(0xFFE0B15A)
        : selected
            ? const Color(0xFF2F6FED)
            : const Color(0xFFD5E4F7);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: current ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanIcon(planId: plan.id),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (current)
                      Text(
                        l10n.currentPlan,
                        style: const TextStyle(color: Color(0xFFE0B15A), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                      ),
                    Text(plan.title, style: const TextStyle(color: Color(0xFF1C1B22), fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.free ? '0 смн' : '${formatShopAmount(somoni)} смн',
                    style: const TextStyle(color: Color(0xFF1C1B22), fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  if (!plan.free && yuan > 0)
                    Text(
                      '¥${formatShopAmount(yuan)}',
                      style: const TextStyle(color: Color(0xFFE0B15A), fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  Text(
                    plan.free ? l10n.freeWord : '/ ${l10n.periodMonths(period.months)}',
                    style: const TextStyle(color: Color(0xFF6E6A78), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (!plan.free && period.months > 1 && somoni > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                yuan > 0
                    ? l10n.monthlyLine(formatShopAmount(somoni / period.months), formatShopAmount(yuan / period.months))
                    : l10n.monthlyLine(formatShopAmount(somoni / period.months), ''),
                style: const TextStyle(color: Color(0xFF6E6A78), fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_rounded, color: Color(0xFF2F6FED), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.planFeature(feature), style: const TextStyle(color: Color(0xFF1C1B22), fontSize: 13)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (current)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.autoRenewOff,
                    style: const TextStyle(color: Color(0xFF1C1B22), fontSize: 14),
                  ),
                ),
                Switch(
                  value: autoRenew,
                  onChanged: onAutoRenew,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF2F6FED),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (offer?.amountSomoni ?? 0) > 0 || plan.free ? onSelect : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6FED),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD5E4F7),
                  disabledForegroundColor: const Color(0xFF8A8496),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l10n.choosePlan, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

String formatShopAmount(num value) {
  final rounded = (value * 100).round() / 100;
  if ((rounded - rounded.round()).abs() < 0.001) return rounded.round().toString();
  return rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

class _PlanIcon extends StatelessWidget {
  const _PlanIcon({required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context) {
    final vip = planId == 'vip';
    final standard = planId == 'standard';
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: vip
            ? const Color(0xFFF8EBD0)
            : standard
                ? const Color(0xFFE7EEF8)
                : const Color(0xFFE3EEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: vip
          ? const CrownIcon(size: 20, color: Color(0xFFE0B15A))
          : Icon(
              standard ? Icons.shield_rounded : Icons.diamond_rounded,
              color: standard ? const Color(0xFF3D6FBE) : const Color(0xFF2F6FED),
              size: 20,
            ),
    );
  }
}
