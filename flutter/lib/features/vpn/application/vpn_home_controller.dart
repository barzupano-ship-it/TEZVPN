import '../../../shop_controller.dart';
import '../../../l10n.dart';

enum VpnVisualState { disconnected, connecting, disconnecting, connected }

/// Read-only view of the existing shop VPN state.
/// Connection itself stays in [ShopController].
class VpnHomeController {
  const VpnHomeController(this.shop);

  final ShopController shop;

  L10n get l10n => shop.l10n;

  VpnVisualState get state {
    if (shop.disconnecting) return VpnVisualState.disconnecting;
    if (shop.connecting) return VpnVisualState.connecting;
    if (shop.vpnOn) return VpnVisualState.connected;
    return VpnVisualState.disconnected;
  }

  String get statusLabel {
    switch (state) {
      case VpnVisualState.connecting:
        return l10n.connectingDots;
      case VpnVisualState.disconnecting:
        return l10n.disconnectingDots;
      case VpnVisualState.connected:
        return l10n.connectedLabel;
      case VpnVisualState.disconnected:
        return l10n.notConnected;
    }
  }

  String get buttonLabel {
    switch (state) {
      case VpnVisualState.connecting:
        return l10n.connectingDots;
      case VpnVisualState.disconnecting:
        return l10n.disconnectingDots;
      case VpnVisualState.connected:
        return l10n.tapToDisconnect;
      case VpnVisualState.disconnected:
        return l10n.tapToConnect;
    }
  }

  /// Calls the real tunnel. If there is no config, the shop opens plans.
  Future<void> toggle() => shop.toggleVpn();

  /// Current purchase path is the shop. Store billing is not wired.
  void openPremium() => shop.go('home');

  void openTab(int index) {
    const screens = ['vpn', 'home', 'settings', 'support'];
    shop.go(screens[index]);
  }

  int get tab {
    switch (shop.screen) {
      case 'home':
      case 'order':
      case 'pay':
        return 1;
      case 'settings':
      case 'account':
      case 'device-signin':
      case 'netshield':
      case 'split':
      case 'killswitch':
      case 'protocol':
      case 'accelerator':
      case 'advanced':
      case 'language':
      case 'privacy-note':
        return 2;
      case 'support':
        return 3;
      default:
        return 0;
    }
  }
}
