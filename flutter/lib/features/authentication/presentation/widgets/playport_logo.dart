import 'package:flutter/material.dart';

class PlayportLogo extends StatefulWidget {
  const PlayportLogo({super.key});

  @override
  State<PlayportLogo> createState() => _PlayportLogoState();
}

class _PlayportLogoState extends State<PlayportLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _fade.value = 1;
    } else if (_fade.value == 0 && !_fade.isAnimating) {
      _fade.forward();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Image.asset(
              'assets/images/sultan_logo.png',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'SULTAN VPN',
            style: TextStyle(
              color: Color(0xFF1A1C1E),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

