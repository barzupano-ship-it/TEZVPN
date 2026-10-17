import 'package:flutter/material.dart';

class VpnBottomNavigation extends StatelessWidget {
  const VpnBottomNavigation({super.key, required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const _icons = [
    Icons.home_rounded,
    Icons.card_giftcard_rounded,
    Icons.person_rounded,
    Icons.support_agent_rounded,
  ];

  static const _labels = ['Home', 'Subscription', 'Profile', 'Support'];
  static const _size = 64.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    final width = _icons.length * _size + (_icons.length - 1) * _gap;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Center(
        child: SizedBox(
          width: width,
          height: _size,
          child: Stack(
            children: [
              Row(
                children: [
                  for (var i = 0; i < _icons.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    const _IdleDot(),
                  ],
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeInOutCubic,
                left: index * (_size + _gap),
                top: 0,
                width: _size,
                height: _size,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2F6FED),
                    boxShadow: [
                      BoxShadow(color: Color(0x592F6FED), blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _icons.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    _NavDot(
                      icon: _icons[i],
                      label: _labels[i],
                      selected: index == i,
                      onTap: () => onSelected(i),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdleDot extends StatelessWidget {
  const _IdleDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VpnBottomNavigation._size,
      height: VpnBottomNavigation._size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF4F5F7),
        border: Border.all(color: const Color(0xFFE1E3E8)),
      ),
    );
  }
}

class _NavDot extends StatelessWidget {
  const _NavDot({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: VpnBottomNavigation._size,
          height: VpnBottomNavigation._size,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: selected ? 1 : 0),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeInOutCubic,
              builder: (context, t, _) {
                return Icon(
                  icon,
                  size: 24 + (6 * t),
                  color: Color.lerp(const Color(0xFF3A3D42), Colors.white, t),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
