import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/vpn_home_controller.dart';

class VpnWaveformWidget extends StatefulWidget {
  const VpnWaveformWidget({super.key, required this.state});

  final VpnVisualState state;

  @override
  State<VpnWaveformWidget> createState() => _VpnWaveformWidgetState();
}

class _VpnWaveformWidgetState extends State<VpnWaveformWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: const Duration(seconds: 18));
  }

  @override
  void didUpdateWidget(VpnWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _sync();
  }

  void _sync() {
    final reduce = !mounted || MediaQuery.disableAnimationsOf(context);
    final still = widget.state == VpnVisualState.disconnected || widget.state == VpnVisualState.disconnecting;
    if (reduce || still) {
      _motion.stop();
      return;
    }
    _motion.duration = widget.state == VpnVisualState.connecting
        ? const Duration(seconds: 26)
        : const Duration(seconds: 16);
    if (!_motion.isAnimating) _motion.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WavePainter(motion: _motion, state: widget.state),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.motion, required this.state}) : super(repaint: motion);

  final Animation<double> motion;
  final VpnVisualState state;

  static const _violet = Color(0xFF2F6FED);
  static const _deep = Color(0xFF1D4ED8);
  static const _light = Color(0xFF7EAEFF);
  static const _red = Color(0xFFE5484D);
  static const _redDeep = Color(0xFFC4232C);
  static const _redLight = Color(0xFFFF9AA6);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.46;
    final t = motion.value * math.pi * 2;
    final moving = state == VpnVisualState.connected || state == VpnVisualState.connecting;
    final off = state == VpnVisualState.disconnected || state == VpnVisualState.disconnecting;
    final breathe = moving ? math.sin(t) * 0.025 : 0.0;
    final glow = off ? _red : _violet;

    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()
        ..color = glow.withValues(alpha: moving ? 0.10 : 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawCircle(
      center,
      radius * 0.98,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFD9D2EA).withValues(alpha: 0.9),
    );

    _sphere(
      canvas,
      center,
      radius * (0.92 + breathe),
      moving ? t : 0.6,
      0.9,
      32,
      48,
      off ? _red : _violet,
    );
    _sphere(
      canvas,
      center,
      radius * (0.78 + breathe * 0.5),
      moving ? t * 0.7 + 1.7 : 1.4,
      0.42,
      22,
      32,
      off ? _redDeep : _deep,
    );
    _sphere(
      canvas,
      center,
      radius * 0.62,
      moving ? t * 1.1 + 2.4 : 2.2,
      0.24,
      14,
      22,
      off ? _redLight : _light,
    );
  }

  void _sphere(
    Canvas canvas,
    Offset center,
    double radius,
    double phase,
    double strength,
    int bands,
    int samples,
    Color color,
  ) {
    const tilt = 0.62;
    final cy = math.cos(tilt);
    final sy = math.sin(tilt);
    for (var i = 0; i < bands; i++) {
      final phi = (i + 0.5) / bands * math.pi;
      final ring = math.sin(phi);
      final y0 = math.cos(phi);
      final count = math.max(10, (samples * ring).round());
      for (var j = 0; j < count; j++) {
        final theta = j / count * math.pi * 2 + phase;
        final x = ring * math.cos(theta);
        final z0 = ring * math.sin(theta);
        final y = y0 * cy - z0 * sy;
        final z = y0 * sy + z0 * cy;
        final depth = ((z + 1) / 2).clamp(0.0, 1.0);
        final dot = center + Offset(x * radius, y * radius);
        final paint = Paint()..color = color.withValues(alpha: (0.04 + 0.86 * depth) * strength);
        canvas.drawCircle(dot, 0.4 + depth * 0.95, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.motion != motion;
  }
}
