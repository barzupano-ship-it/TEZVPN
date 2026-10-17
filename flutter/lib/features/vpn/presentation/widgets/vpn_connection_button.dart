import 'package:flutter/material.dart';

class VpnConnectionButton extends StatefulWidget {
  const VpnConnectionButton({
    super.key,
    required this.label,
    required this.busy,
    this.disconnect = false,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final bool disconnect;
  final VoidCallback onPressed;

  @override
  State<VpnConnectionButton> createState() => _VpnConnectionButtonState();
}

class _VpnConnectionButtonState extends State<VpnConnectionButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final diameter = (MediaQuery.sizeOf(context).width * 0.31).clamp(110.0, 128.0);
    final colors = widget.disconnect
        ? const [Color(0xFFFF9AA6), Color(0xFFE5484D), Color(0xFFC4232C)]
        : const [Color(0xFF8EB6FF), Color(0xFF2F6FED), Color(0xFF1D4ED8)];
    final glow = widget.disconnect ? const Color(0xFFE5484D) : const Color(0xFF2F6FED);
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
                stops: const [0, 0.45, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.white.withValues(alpha: widget.busy ? 0.7 : 1),
                  size: 28,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
