import 'package:flutter/material.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class ToggleCard extends StatelessWidget {
  final FeatureToggle toggle;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ToggleCard({
    super.key,
    required this.toggle,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  static Color _envColor(String env) {
    switch (env) {
      case 'DEV': return AppColors.teal;
      case 'TEST': return AppColors.yellow;
      case 'PROD': return AppColors.coral;
      default: return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1E2040),
        border: Border.all(
          color: toggle.enabled
              ? AppColors.green.withOpacity(0.25)
              : AppColors.coral.withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Toggle switch — only thumb position is animated
            GestureDetector(
              onTap: onToggle != null ? () => onToggle!(!toggle.enabled) : null,
              child: Container(
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: toggle.enabled
                      ? AppColors.green.withOpacity(0.3)
                      : AppColors.coral.withOpacity(0.2),
                  border: Border.all(
                    color: toggle.enabled
                        ? AppColors.green.withOpacity(0.5)
                        : AppColors.coral.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: toggle.enabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: toggle.enabled
                          ? AppColors.green
                          : AppColors.coral,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Name + description + envs
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toggle.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: toggle.enabled
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                  if (toggle.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      toggle.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.35),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (toggle.environments.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: toggle.environments.map((env) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: _envColor(env).withOpacity(0.15),
                          ),
                          child: Text(
                            env,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _envColor(env),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Edit button
            if (onEdit != null) ...[
              _ActionButton(icon: Icons.edit_outlined, onTap: onEdit!),
              const SizedBox(width: 4),
            ],

            // Delete button
            if (onDelete != null)
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                onTap: onDelete!,
                hoverColor: AppColors.coral,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.hoverColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _hovering
                ? Colors.white.withOpacity(0.10)
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _hovering
                ? (widget.hoverColor ?? Colors.white.withOpacity(0.8))
                : Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
