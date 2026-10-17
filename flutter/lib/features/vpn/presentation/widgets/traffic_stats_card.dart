import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../vpn_channel.dart';

class TrafficStatsRow extends StatefulWidget {
  const TrafficStatsRow({
    super.key,
    this.active = false,
    this.uploadBytesPerSecond = 0,
    this.downloadBytesPerSecond = 0,
    this.uploadLabel = 'Отдача',
    this.downloadLabel = 'Загрузка',
  });

  final bool active;
  final double uploadBytesPerSecond;
  final double downloadBytesPerSecond;
  final String uploadLabel;
  final String downloadLabel;

  @override
  State<TrafficStatsRow> createState() => _TrafficStatsRowState();
}

class _TrafficStatsRowState extends State<TrafficStatsRow> {
  final VpnChannel _vpn = VpnChannel();
  Timer? _timer;
  int? _lastUp;
  int? _lastDown;
  DateTime? _lastAt;
  late double _upload = widget.uploadBytesPerSecond;
  late double _download = widget.downloadBytesPerSecond;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(TrafficStatsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _upload = 0;
      _download = 0;
      _lastUp = null;
      _lastDown = null;
      _lastAt = null;
      _arm();
    }
  }

  void _arm() {
    _timer?.cancel();
    _timer = null;
    if (!widget.active) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _sample());
    _sample();
  }

  Future<void> _sample() async {
    final sample = await _vpn.traffic();
    if (!mounted || !widget.active) return;
    final now = DateTime.now();
    final previousUp = _lastUp;
    final previousDown = _lastDown;
    final previousAt = _lastAt;
    _lastUp = sample.up;
    _lastDown = sample.down;
    _lastAt = now;
    if (previousUp == null || previousDown == null || previousAt == null) return;
    final seconds = now.difference(previousAt).inMilliseconds / 1000.0;
    final upDelta = sample.up - previousUp;
    final downDelta = sample.down - previousDown;
    if (seconds < 0.2 || upDelta < 0 || downDelta < 0) return;
    setState(() {
      _upload = upDelta / seconds;
      _download = downDelta / seconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TrafficStatsCard(
              icon: Icons.arrow_upward_rounded,
              label: widget.uploadLabel,
              bytesPerSecond: widget.active ? _upload : 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TrafficStatsCard(
              icon: Icons.arrow_downward_rounded,
              label: widget.downloadLabel,
              bytesPerSecond: widget.active ? _download : 0,
            ),
          ),
        ],
      ),
    );
  }
}

class TrafficStatsCard extends StatelessWidget {
  const TrafficStatsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.bytesPerSecond,
  });

  final IconData icon;
  final String label;
  final double bytesPerSecond;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD5E4F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE3EEFF),
            ),
            child: Icon(icon, size: 15, color: Color(0xFF2F5F9A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF6E6A78), fontSize: 12)),
                Text(
                  formatTransferSpeed(bytesPerSecond),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF1C1B22), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatTransferSpeed(double bytesPerSecond) {
  final value = bytesPerSecond < 0 ? 0.0 : bytesPerSecond;
  if (value >= 1024 * 1024 * 1024) {
    return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }
  if (value >= 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
  if (value >= 1024) {
    return '${(value / 1024).toStringAsFixed(0)} KB/s';
  }
  if (value == 0) return '0 KB/s';
  return '${value.toStringAsFixed(0)} B/s';
}
