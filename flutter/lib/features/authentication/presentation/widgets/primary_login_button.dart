import 'package:flutter/material.dart';

class PrimaryLoginButton extends StatefulWidget {
  const PrimaryLoginButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.filled = true,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool filled;
  final bool busy;

  @override
  State<PrimaryLoginButton> createState() => _PrimaryLoginButtonState();
}

class _PrimaryLoginButtonState extends State<PrimaryLoginButton> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scale = _down && !reduce ? 0.98 : 1.0;
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 90),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: _down && !reduce ? 0.9 : 1,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.filled ? const Color(0xFF2F6FED) : const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(23),
              border: widget.filled ? null : Border.all(color: const Color(0xFFD9D2EA)),
            ),
            child: widget.busy
                ? Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.filled ? Colors.white : const Color(0xFF2F5F9A),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            color: widget.filled ? const Color(0xFFFFFFFF) : const Color(0xFF1C1B22),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: widget.filled ? Colors.white : const Color(0xFF1C1B22),
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
