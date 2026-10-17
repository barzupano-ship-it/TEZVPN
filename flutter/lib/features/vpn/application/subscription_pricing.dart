import '../../../models.dart';

enum BillingPeriod {
  oneMonth(1, '1 месяц'),
  threeMonths(3, '3 месяца'),
  sixMonths(6, '6 месяцев'),
  twelveMonths(12, '12 месяцев');

  const BillingPeriod(this.months, this.label, {this.badge});

  final int months;
  final String label;
  final String? badge;
}

/// Total charged for one plan over one billing period.
/// [shopPlanId] is the current shop order product.
/// [storeProductId] is reserved for App Store / Google Play and is unused until billing is connected.
class PeriodOffer {
  const PeriodOffer({
    required this.period,
    required this.amountSomoni,
    required this.amountYuan,
    required this.shopPlanId,
    this.storeProductId = '',
    this.discountBadge,
  });

  final BillingPeriod period;
  final int amountSomoni;
  final int amountYuan;
  final String shopPlanId;
  final String storeProductId;
  final String? discountBadge;
}

class SubscriptionPlanSpec {
  const SubscriptionPlanSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.free,
    required this.offers,
    required this.features,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool free;
  final List<PeriodOffer> offers;
  final List<String> features;

  PeriodOffer? offerFor(BillingPeriod period) {
    for (final offer in offers) {
      if (offer.period == period) return offer;
    }
    return null;
  }
}

class ResolvedOffer {
  const ResolvedOffer({
    required this.amountSomoni,
    required this.amountYuan,
    required this.shopPlanId,
    required this.storeProductId,
    required this.discountBadge,
  });

  final double amountSomoni;
  final double amountYuan;
  final String shopPlanId;
  final String storeProductId;
  final String? discountBadge;

  bool get canOrder => shopPlanId.isNotEmpty && amountSomoni > 0;
}

/// Shop totals for the live tariffs: 1m1, 3m2, 6m4, 12m4.
/// Live shop prices replace these amounts when the same product id is loaded.
class SubscriptionPricing {
  const SubscriptionPricing._();

  static const plans = <SubscriptionPlanSpec>[
    SubscriptionPlanSpec(
      id: 'standard',
      title: 'Standard',
      subtitle: 'Обычный доступ',
      free: false,
      features: [
        '3 устройства',
      ],
      offers: [
        PeriodOffer(period: BillingPeriod.oneMonth, amountSomoni: 25, amountYuan: 18, shopPlanId: 'std1'),
        PeriodOffer(period: BillingPeriod.threeMonths, amountSomoni: 65, amountYuan: 47, shopPlanId: 'std3'),
        PeriodOffer(period: BillingPeriod.sixMonths, amountSomoni: 130, amountYuan: 94, shopPlanId: 'std6'),
        PeriodOffer(
          period: BillingPeriod.twelveMonths,
          amountSomoni: 210,
          amountYuan: 151,
          shopPlanId: 'std12',
        ),
      ],
    ),
    SubscriptionPlanSpec(
      id: 'premium',
      title: 'Premium',
      subtitle: 'Расширенная защита',
      free: false,
      features: [
        '3 устройства',
      ],
      offers: [
        PeriodOffer(period: BillingPeriod.oneMonth, amountSomoni: 42, amountYuan: 30, shopPlanId: '1m1'),
        PeriodOffer(period: BillingPeriod.threeMonths, amountSomoni: 104, amountYuan: 75, shopPlanId: '3m2'),
        PeriodOffer(period: BillingPeriod.sixMonths, amountSomoni: 215, amountYuan: 155, shopPlanId: '6m4'),
        PeriodOffer(
          period: BillingPeriod.twelveMonths,
          amountSomoni: 348,
          amountYuan: 250,
          shopPlanId: '12m4',
        ),
      ],
    ),
    SubscriptionPlanSpec(
      id: 'vip',
      title: 'VIP',
      subtitle: 'Максимум возможностей',
      free: false,
      features: [
        '3 устройства',
      ],
      offers: [
        PeriodOffer(period: BillingPeriod.oneMonth, amountSomoni: 76, amountYuan: 55, shopPlanId: 'prem1'),
        PeriodOffer(period: BillingPeriod.threeMonths, amountSomoni: 190, amountYuan: 137, shopPlanId: 'prem3'),
        PeriodOffer(period: BillingPeriod.sixMonths, amountSomoni: 390, amountYuan: 281, shopPlanId: 'prem6'),
        PeriodOffer(
          period: BillingPeriod.twelveMonths,
          amountSomoni: 630,
          amountYuan: 453,
          shopPlanId: 'prem12',
        ),
      ],
    ),
  ];

  static SubscriptionPlanSpec? find(String id) {
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  static ResolvedOffer? resolve(SubscriptionPlanSpec plan, BillingPeriod period, List<Plan> live) {
    if (plan.free) {
      return const ResolvedOffer(
        amountSomoni: 0,
        amountYuan: 0,
        shopPlanId: '',
        storeProductId: '',
        discountBadge: null,
      );
    }
    final offer = plan.offerFor(period);
    if (offer == null) return null;
    final match = _livePlan(offer, period, live);
    return ResolvedOffer(
      amountSomoni: match == null ? offer.amountSomoni.toDouble() : match.tjs,
      amountYuan: match == null || match.cny <= 0 ? offer.amountYuan.toDouble() : match.cny,
      shopPlanId: match?.id ?? offer.shopPlanId,
      storeProductId: offer.storeProductId,
      discountBadge: offer.discountBadge,
    );
  }

  static Plan? _livePlan(PeriodOffer offer, BillingPeriod period, List<Plan> live) {
    if (offer.shopPlanId.isEmpty) return null;
    for (final plan in live) {
      if (plan.id == offer.shopPlanId) return plan;
    }
    final expires = _expiresFor(period);
    final matches = [
      for (final plan in live)
        if (expires.contains(plan.expires.toLowerCase())) plan,
    ];
    if (matches.length == 1) return matches.first;
    return null;
  }

  static Set<String> _expiresFor(BillingPeriod period) {
    switch (period) {
      case BillingPeriod.oneMonth:
        return const {'30d'};
      case BillingPeriod.threeMonths:
        return const {'90d'};
      case BillingPeriod.sixMonths:
        return const {'180d'};
      case BillingPeriod.twelveMonths:
        return const {'365d', '360d'};
    }
  }
}
