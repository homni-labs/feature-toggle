import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/theme/app_colors.dart';

/// Cartoon-style action button with hover lift and press push animation,
/// matching the Keycloak login `.comic-btn` style.
class ComicButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool expand;

  const ComicButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color,
    this.expand = false,
  });

  @override
  State<ComicButton> createState() => _ComicButtonState();
}

class _ComicButtonState extends State<ComicButton> {
  bool _hovering = false;
  bool _pressing = false;

  Offset get _offset {
    if (_pressing) return const Offset(3, 3);
    if (_hovering) return const Offset(-2, -2);
    return Offset.zero;
  }

  Offset get _shadow {
    if (_pressing) return const Offset(2, 2);
    if (_hovering) return const Offset(7, 7);
    return const Offset(5, 5);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressing = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) {
          setState(() => _pressing = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressing = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.color ?? AppColors.coral,
            border: Border.all(width: 3, color: AppColors.navy),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy,
                offset: _shadow,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
