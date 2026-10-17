import 'package:flutter/material.dart';

class GamingCollage extends StatefulWidget {
  const GamingCollage({super.key});

  @override
  State<GamingCollage> createState() => _GamingCollageState();
}

class _GamingCollageState extends State<GamingCollage> with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final shift = reduce ? 0.0 : (_drift.value - 0.5) * 8;
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            const ColoredBox(color: Color(0xFF101214)),
            Transform.translate(
              offset: Offset(shift, shift * 0.4),
              child: const _Tiles(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0xCCFFFFFF),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0, 0.28, 0.78, 1],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles();

  static const _tiles = <_Tile>[
    _Tile('assets/images/collage_knight.jpg', -0.08, -0.08, 0.42, -0.08),
    _Tile('assets/images/collage_traveler.jpg', 0.30, -0.12, 0.38, 0.06),
    _Tile('assets/images/collage_valley.jpg', 0.64, -0.04, 0.42, -0.05),
    _Tile('assets/images/collage_soldier.jpg', -0.02, 0.34, 0.36, 0.07),
    _Tile('assets/images/collage_creature.jpg', 0.32, 0.30, 0.34, -0.06),
    _Tile('assets/images/collage_racer.jpg', 0.62, 0.32, 0.40, 0.08),
    _Tile('assets/images/collage_valley.jpg', 0.16, 0.58, 0.30, 0.04),
    _Tile('assets/images/collage_knight.jpg', 0.48, 0.56, 0.32, -0.07),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final tile in _tiles)
              Positioned(
                left: tile.left * w,
                top: tile.top * h,
                width: tile.size * w,
                height: tile.size * w * 0.92,
                child: Transform.rotate(
                  angle: tile.turns,
                  child: _TileImage(asset: tile.asset),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tile {
  const _Tile(this.asset, this.left, this.top, this.size, this.turns);
  final String asset;
  final double left;
  final double top;
  final double size;
  final double turns;
}

class _TileImage extends StatelessWidget {
  const _TileImage({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const ColoredBox(color: Color(0xFF2C3136)),
        ),
      ),
    );
  }
}
