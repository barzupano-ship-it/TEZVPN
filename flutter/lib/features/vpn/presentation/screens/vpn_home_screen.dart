import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shop_controller.dart';
import '../../application/vpn_home_controller.dart';
import '../widgets/traffic_stats_card.dart';
import '../widgets/vpn_connection_button.dart';
import '../widgets/vpn_status_header.dart';
import '../widgets/vpn_waveform_widget.dart';

class VpnHomeScreen extends StatelessWidget {
  const VpnHomeScreen({super.key, required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    final home = VpnHomeController(shop);
    return Column(
      children: [
        VpnStatusHeader(status: home.statusLabel, onPremium: () => StoreSubscription.open(shop)),
        if (shop.error != null && !shop.vpnOn)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              shop.error!,
              style: const TextStyle(color: Color(0xFFC62828), fontSize: 12),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = math.min(constraints.maxWidth - 24, constraints.maxHeight).clamp(180.0, 360.0);
              return Center(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VpnWaveformWidget(state: home.state),
                      VpnConnectionButton(
                        label: home.buttonLabel,
                        busy: home.state == VpnVisualState.connecting,
                        disconnect: home.state == VpnVisualState.disconnected || home.state == VpnVisualState.disconnecting,
                        onPressed: home.toggle,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        TrafficStatsRow(
          uploadLabel: shop.l10n.upload,
          downloadLabel: shop.l10n.download,
          active: shop.vpnOn,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
