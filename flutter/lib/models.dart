class ShopState {
  final List<Plan> plans;
  final PayInfo pay;
  final Order? order;
  final List<Order> orders;
  final VpnConfig? config;
  final Account? account;
  final Meta meta;
  final String? flash;

  const ShopState({
    this.plans = const [],
    this.pay = const PayInfo(),
    this.order,
    this.orders = const [],
    this.config,
    this.account,
    this.meta = const Meta(),
    this.flash,
  });

  ShopState copyWith({
    List<Plan>? plans,
    PayInfo? pay,
    Order? order,
    List<Order>? orders,
    VpnConfig? config,
    Account? account,
    Meta? meta,
    String? flash,
    bool clearFlash = false,
  }) {
    return ShopState(
      plans: plans ?? this.plans,
      pay: pay ?? this.pay,
      order: order ?? this.order,
      orders: orders ?? this.orders,
      config: config ?? this.config,
      account: account ?? this.account,
      meta: meta ?? this.meta,
      flash: clearFlash ? flash : (flash ?? this.flash),
    );
  }
}

class Plan {
  final String id;
  final String title;
  final double tjs;
  final double cny;
  final int devices;
  final String expires;

  const Plan({
    required this.id,
    required this.title,
    required this.tjs,
    required this.cny,
    this.devices = 1,
    this.expires = '',
  });
}

class PayInfo {
  final String alif;
  final String dc;
  final String payee;
  final String support;
  final bool wechat;
  final bool alipay;

  const PayInfo({
    this.alif = '',
    this.dc = '',
    this.payee = '',
    this.support = '',
    this.wechat = false,
    this.alipay = false,
  });
}

class Order {
  final String id;
  final String plan;
  final String title;
  final String amount;
  final String status;
  final String statusLabel;
  final String name;
  final bool ready;

  const Order({
    required this.id,
    this.plan = '',
    this.title = '',
    this.amount = '',
    this.status = '',
    this.statusLabel = '',
    this.name = '',
    this.ready = false,
  });
}

class Account {
  final String code;
  const Account({this.code = ''});
}

class Meta {
  final String title;
  final String bot;
  final String support;

  const Meta({
    this.title = 'TEZVPN',
    this.bot = 'teztezvpn_bot',
    this.support = 'BarzuRizoev',
  });
}

class VpnConfig {
  final String sid;
  final List<VpnDevice> devices;
  const VpnConfig({this.sid = '', this.devices = const []});
}

class VpnDevice {
  final String name;
  final String conf;
  final String vpnuri;
  final String xray;
  final String hysteria2;
  final String sub;
  const VpnDevice({
    required this.name,
    required this.conf,
    this.vpnuri = '',
    this.xray = '',
    this.hysteria2 = '',
    this.sub = '',
  });
}
