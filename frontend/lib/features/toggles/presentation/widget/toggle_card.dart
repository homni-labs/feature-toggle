import 'package:flutter/material.dart';

import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/features/toggles/domain/model/feature_toggle.dart';
import 'package:togli_app/features/toggles/domain/model/toggle_environment.dart';

/// Tile-style toggle card matching `app-redesign.html` Toggles section.
///
/// Layout:
/// - Top stripe (4px): green gradient = all ON, coral/yellow = mixed, gray = all OFF
/// - Head: icon (38×38 gradient) + name (monospace bold)
/// - Description (2 lines max)
/// - Env cells grid: each cell has env label + mini toggle switch (green=ON, red=OFF)
/// - Actions: edit/delete in top-right corner
class ToggleCard extends StatefulWidget {
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

  @override
  State<ToggleCard> createState() => _ToggleCardState();
}

class _ToggleCardState extends State<ToggleCard> {
  bool _hovering = false;

  bool get _allOn =>
      widget.toggle.environments.isNotEmpty &&
      widget.toggle.environments.every((e) => e.enabled);

  bool get _allOff =>
      widget.toggle.environments.isEmpty ||
      widget.toggle.environments.every((e) => !e.enabled);

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = _buildActions();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(width: 3, color: AppColors.navy),
          boxShadow: [
            BoxShadow(
              color: _hovering ? AppColors.navy : const Color(0xFFDDD8CC),
              offset: Offset(0, _hovering ? 6 : 3),
            ),
          ],
        ),
        transform: _hovering
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top stripe ──────────────────────────────────
                _Stripe(name: widget.toggle.name),

                // ── Head: icon + name ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: _Head(toggle: widget.toggle),
                ),

                // ── Description (fixed height) ──────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SizedBox(
                    height: 40,
                    child: Text(
                      widget.toggle.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.navy.withOpacity(0.55),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Env cells with toggle switches ──────────────
                if (widget.toggle.environments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.toggle.environments
                          .map((env) => _EnvCell(
                                env: env,
                                onToggle: widget.onEnvironmentToggle == null
                                    ? null
                                    : (val) => widget.onEnvironmentToggle!(
                                        env.name, val),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),

            // ── Actions: top-right ──────────────────────────────
            if (actions.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      actions[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    final List<Widget> result = [];
    if (widget.onEdit != null) {
      result.add(_TileAction(
        icon: Icons.edit_outlined,
        accent: AppColors.teal,
        onTap: widget.onEdit!,
      ));
    }
    if (widget.onDelete != null) {
      result.add(_TileAction(
        icon: Icons.delete_outline_rounded,
        accent: AppColors.coral,
        onTap: widget.onDelete!,
      ));
    }
    return result;
  }
}

// ── Top stripe (random gradient from name hash) ──────────────────

class _Stripe extends StatelessWidget {
  const _Stripe({required this.name});
  final String name;

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
    final int hash = name.codeUnits.fold<int>(0, (a, c) => a + c);
    final colors = _gradients[hash % _gradients.length];
    return Container(
      height: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
      ),
    );
  }
}

// ── Head ──────────────────────────────────────────────────────────

class _Head extends StatelessWidget {
  const _Head({required this.toggle});
  final FeatureToggle toggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToggleIcon(name: toggle.name),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            toggle.name,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

// ── Toggle icon (generated gradient from name hash) ───────────────

class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final int hash = name.codeUnits.fold<int>(0, (a, c) => a + c);
    const palette = <List<Color>>[
      [AppColors.coral, AppColors.yellow],
      [AppColors.teal, AppColors.purple],
      [AppColors.purple, AppColors.coral],
      [AppColors.teal, AppColors.green],
      [AppColors.green, AppColors.teal],
      [AppColors.yellow, AppColors.coral],
      [AppColors.purple, AppColors.teal],
      [AppColors.yellow, AppColors.green],
    ];
    final colors = palette[hash % palette.length];

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 2, color: AppColors.navy),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'T',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Env cell with mini toggle switch ──────────────────────────────

class _EnvCell extends StatefulWidget {
  const _EnvCell({required this.env, required this.onToggle});
  final ToggleEnvironment env;
  final ValueChanged<bool>? onToggle;

  @override
  State<_EnvCell> createState() => _EnvCellState();
}

class _EnvCellState extends State<_EnvCell> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isOn = widget.env.enabled;
    final bool interactive = widget.onToggle != null;

    return MouseRegion(
      cursor:
          interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: interactive ? () => widget.onToggle!(!isOn) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isOn
                ? AppColors.green.withOpacity(0.06)
                : const Color(0xFFF5F2EB),
            border: Border.all(
              width: 2,
              color: isOn
                  ? AppColors.green.withOpacity(0.4)
                  : const Color(0xFFDDD8CC),
            ),
          ),
          child: Column(
            children: [
              Text(
                widget.env.name,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isOn ? AppColors.navy : AppColors.navy.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Mini toggle switch
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isOn ? AppColors.green : AppColors.coral,
                  border: Border.all(width: 2, color: AppColors.navy),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  alignment:
                      isOn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                          width: 1.5, color: AppColors.navy),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile action button ────────────────────────────────────────────

class _TileAction extends StatefulWidget {
  const _TileAction({
    required this.icon,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_TileAction> createState() => _TileActionState();
}

class _TileActionState extends State<_TileAction> {
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
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.accent.withOpacity(_hovering ? 0.2 : 0.1),
            border: Border.all(
              width: 2,
              color: widget.accent.withOpacity(_hovering ? 0.6 : 0.35),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, size: 14, color: widget.accent),
        ),
      ),
    );
  }
}
