import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/features/environments/domain/model/environment.dart'
    as env_model;

/// Color tile environment card matching pages-redesign.html.
///
/// Layout:
/// - 6px gradient stripe top (env color → 30% opacity)
/// - Environment name in Fredoka bold, colored by env type
/// - Created date meta
/// - Delete button top-right (if permitted)
class EnvironmentCard extends StatefulWidget {
  final env_model.Environment environment;
  final VoidCallback? onDelete;

  const EnvironmentCard({
    super.key,
    required this.environment,
    this.onDelete,
  });

  @override
  State<EnvironmentCard> createState() => _EnvironmentCardState();
}

class _EnvironmentCardState extends State<EnvironmentCard> {
  bool _hovering = false;

  static Color _envColor(String name) {
    switch (name) {
      case 'DEV':
        return AppColors.teal;
      case 'TEST':
        return AppColors.yellow;
      case 'PROD':
        return AppColors.coral;
      default:
        return AppColors.purple;
    }
  }

  // Darker text variant for yellow (yellow on white is unreadable)
  static Color _envTextColor(String name) {
    switch (name) {
      case 'TEST':
        return const Color(0xFFB09020);
      default:
        return _envColor(name);
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _envTextColor(widget.environment.name);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(width: 3, color: AppColors.navy),
          boxShadow: [
            BoxShadow(
              color: _hovering ? AppColors.navy : const Color(0xFFDDD8CC),
              offset: Offset(0, _hovering ? 5 : 3),
            ),
          ],
        ),
        transform: _hovering
            ? Matrix4.translationValues(0, -1, 0)
            : Matrix4.identity(),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient stripe
                _ColorStripe(seed: widget.environment.name),
                // Body
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.environment.name,
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Created ${_formatDate(widget.environment.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.navy.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Delete button
            if (widget.onDelete != null)
              Positioned(
                top: 14,
                right: 14,
                child: _DeleteButton(onTap: widget.onDelete!),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorStripe extends StatelessWidget {
  const _ColorStripe({required this.seed});
  final String seed;

  static const _gradients = <List<Color>>[
    [AppColors.coral, AppColors.yellow],
    [AppColors.teal, AppColors.green],
    [AppColors.purple, AppColors.coral],
    [AppColors.yellow, AppColors.green],
    [AppColors.green, AppColors.teal],
    [AppColors.teal, AppColors.purple],
    [AppColors.coral, AppColors.purple],
    [AppColors.yellow, AppColors.teal],
  ];

  @override
  Widget build(BuildContext context) {
    final int hash = seed.codeUnits.fold<int>(0, (a, c) => a + c);
    final colors = _gradients[hash % _gradients.length];
    return Container(
      height: 6,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
      ),
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: AppColors.coral.withOpacity(_hovering ? 0.15 : 0.06),
            border: Border.all(
              width: 2,
              color: AppColors.coral.withOpacity(_hovering ? 0.6 : 0.35),
            ),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            size: 14,
            color: AppColors.coral,
          ),
        ),
      ),
    );
  }
}
