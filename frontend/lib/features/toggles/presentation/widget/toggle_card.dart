import 'package:flutter/material.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/toggle_environment.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

/// A toggle card. The global on/off switch is gone — each environment chip
/// is its own interactive switch. Click flips the state for that env via
/// [onEnvironmentToggle], which the parent wires to the cubit's optimistic
/// update flow. When [onEnvironmentToggle] is null (read-only mode), the
/// chips render as static badges.
class ToggleCard extends StatelessWidget {
  final FeatureToggle toggle;
  final void Function(String envName, bool enabled)? onEnvironmentToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ToggleCard({
    super.key,
    required this.toggle,
    this.onEnvironmentToggle,
    this.onEdit,
    this.onDelete,
  });

  static Color _envColor(String env) {
    switch (env) {
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

  /// "Active" if at least one env is enabled — drives the card border accent
  /// so a row that has any live flag stands out from a fully-off row.
  bool get _hasAnyEnabled =>
      toggle.environments.any((e) => e.enabled);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1E2040),
        border: Border.all(
          color: _hasAnyEnabled
              ? AppColors.green.withOpacity(0.25)
              : Colors.white.withOpacity(0.10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status dot — small indicator instead of the old big switch
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasAnyEnabled
                      ? AppColors.green
                      : Colors.white.withOpacity(0.18),
                  boxShadow: _hasAnyEnabled
                      ? [
                          BoxShadow(
                            color: AppColors.green.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name + description + per-env switches
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          toggle.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _hasAnyEnabled
                                ? Colors.white
                                : Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                      _CounterBadge(
                        enabled: toggle.environments
                            .where((e) => e.enabled)
                            .length,
                        total: toggle.environments.length,
                      ),
                    ],
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: toggle.environments
                          .map((env) => _EnvSwitchChip(
                                env: env,
                                color: _envColor(env.name),
                                onToggle: onEnvironmentToggle == null
                                    ? null
                                    : (newValue) => onEnvironmentToggle!(
                                          env.name,
                                          newValue,
                                        ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Edit / delete actions, stacked compactly
            Column(
              children: [
                if (onEdit != null) ...[
                  _ActionButton(icon: Icons.edit_outlined, onTap: onEdit!),
                  const SizedBox(height: 2),
                ],
                if (onDelete != null)
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    onTap: onDelete!,
                    hoverColor: AppColors.coral,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Env switch chip ─────────────────────────────────────────────

/// A clickable env chip with built-in state. Filled in env color when
/// enabled, dim/outlined when disabled. The fill/outline animation matches
/// the 200ms style used by the rest of the dialog/card system.
class _EnvSwitchChip extends StatefulWidget {
  const _EnvSwitchChip({
    required this.env,
    required this.color,
    required this.onToggle,
  });

  final ToggleEnvironment env;
  final Color color;
  final ValueChanged<bool>? onToggle;

  @override
  State<_EnvSwitchChip> createState() => _EnvSwitchChipState();
}

class _EnvSwitchChipState extends State<_EnvSwitchChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool readOnly = widget.onToggle == null;
    final bool isOn = widget.env.enabled;

    final Color bg = isOn
        ? widget.color.withOpacity(_hovering ? 0.30 : 0.20)
        : Colors.white.withOpacity(_hovering ? 0.10 : 0.06);
    final Color border = isOn
        ? widget.color.withOpacity(0.5)
        : Colors.white.withOpacity(0.12);
    final Color text =
        isOn ? widget.color : Colors.white.withOpacity(0.4);

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: bg,
        border: Border.all(color: border),
        boxShadow: isOn && _hovering
            ? [
                BoxShadow(
                  color: widget.color.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ON ● / OFF ○ indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? widget.color : Colors.transparent,
              border: Border.all(
                color: isOn
                    ? widget.color
                    : Colors.white.withOpacity(0.35),
                width: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.env.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
              color: text,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    if (readOnly) {
      return Tooltip(
        message:
            '${widget.env.name} • ${isOn ? "enabled" : "disabled"} (read-only)',
        child: chip,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => widget.onToggle!(!isOn),
        child: Tooltip(
          message:
              'Click to ${isOn ? "disable" : "enable"} in ${widget.env.name}',
          child: chip,
        ),
      ),
    );
  }
}

// ── Counter badge ───────────────────────────────────────────────

/// Tiny "n/m on" badge that shows how many of the toggle's envs are
/// currently enabled. Helps scan a long list of toggles at a glance.
class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.enabled, required this.total});

  final int enabled;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final bool allOff = enabled == 0;
    final Color color = allOff
        ? Colors.white.withOpacity(0.3)
        : AppColors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: allOff
            ? Colors.white.withOpacity(0.05)
            : AppColors.green.withOpacity(0.12),
        border: Border.all(
          color: allOff
              ? Colors.white.withOpacity(0.10)
              : AppColors.green.withOpacity(0.25),
        ),
      ),
      child: Text(
        '$enabled/$total on',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Action button (unchanged) ───────────────────────────────────

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
