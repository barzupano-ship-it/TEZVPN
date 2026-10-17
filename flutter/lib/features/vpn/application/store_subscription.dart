import '../../../shop_controller.dart';

/// Hook for App Store and Google Play subscriptions.
/// Purchases stay on the shop plans screen until store billing is added.
class StoreSubscription {
  const StoreSubscription._();

  static void open(ShopController shop) => shop.go('home');
}
