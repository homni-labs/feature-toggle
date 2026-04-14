import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/core/domain/value_objects/project_role.dart';
import 'package:togli_app/features/projects/domain/model/project.dart';

/// Workspace-style project card matching `assets/mockups/projects-redesign.html`.
///
/// Layout:
/// - head: gradient slug avatar (2 letters) + slug + name + optional role badge
/// - description (1-2 lines, truncated)
/// - counters row: Toggles · Envs · Members
/// - actions row: prominent icon buttons (edit / archive / unarchive)
///
/// The role badge is only rendered when [showRoleBadge] is true (i.e. for the
/// regular user view — platform admins have implicit access to every project,
/// so per-card role badges are intentionally hidden in the PA view).
class ProjectCard extends StatefulWidget {
  final Project project;

  /// Show the per-project role badge ("Admin" / "Editor" / "Reader") in the
  /// card head. Pass `false` for Platform Admin view.
  final bool showRoleBadge;

  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  const ProjectCard({
    super.key,
    required this.project,
    required this.showRoleBadge,
    required this.onTap,
    this.onEdit,
    this.onArchive,
    this.onUnarchive,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Project p = widget.project;
    final bool isArchived = p.archived;
    final List<Widget> actions = _buildActions();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 3,
              color: AppColors.navy,
            ),
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
          child: Opacity(
            opacity: isArchived ? 0.6 : 1.0,
            child: Stack(
              children: [
                // Card content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ColorStripe(seed: p.slug.value),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Head(
                            project: p,
                            showRoleBadge: widget.showRoleBadge,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 40,
                            child: Text(
                              (p.description != null &&
                                      p.description!.isNotEmpty)
                                  ? p.description!
                                  : '',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.navy.withOpacity(0.55),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Counters(
                            toggles: p.togglesCount,
                            envs: p.environmentsCount,
                            members: p.membersCount,
                            isArchived: isArchived,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Actions top-right
                if (actions.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          actions[i],
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the icon-only action buttons that should be visible for the
  /// current card state. The screen filters which callbacks to pass based on
  /// permissions, so we just render whichever ones are non-null.
  List<Widget> _buildActions() {
    final List<Widget> result = [];
    if (widget.onEdit != null) {
      result.add(_ActionButton(
        icon: Icons.edit_outlined,
        tooltip: 'Edit project',
        accent: AppColors.teal,
        onTap: widget.onEdit!,
      ));
    }
    if (widget.onArchive != null) {
      result.add(_ActionButton(
        icon: Icons.inventory_2_outlined,
        tooltip: 'Archive project',
        accent: AppColors.yellow,
        onTap: widget.onArchive!,
      ));
    }
    if (widget.onUnarchive != null) {
      result.add(_ActionButton(
        icon: Icons.unarchive_outlined,
        tooltip: 'Unarchive project',
        accent: AppColors.green,
        onTap: widget.onUnarchive!,
      ));
    }
    return result;
  }
}

// ── Card head ──────────────────────────────────────────────────

class _Head extends StatelessWidget {
  const _Head({required this.project, required this.showRoleBadge});

  final Project project;
  final bool showRoleBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlugAvatar(slug: project.slug.value, archived: project.archived),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.slug.value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coral,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (showRoleBadge && project.myRole != null) ...[
                const SizedBox(height: 6),
                _RoleBadge(role: project.myRole!),
              ] else if (project.archived) ...[
                const SizedBox(height: 6),
                const _ArchivedBadge(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Color stripe (random from seed) ───────────────────────────

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
      height: 5,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
      ),
    );
  }
}

// ── Slug avatar ────────────────────────────────────────────────

class _SlugAvatar extends StatelessWidget {
  const _SlugAvatar({required this.slug, required this.archived});

  final String slug;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final String monogram = _monogramFor(slug);
    final List<Color> colors = _gradientFor(slug);

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(width: 3, color: AppColors.navy),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: archived
              ? [const Color(0xFFBBBBBB), const Color(0xFFCCCCCC)]
              : colors,
        ),
      ),
      child: ColorFiltered(
        colorFilter: archived
            ? const ColorFilter.mode(
                Color(0xFFBBBBBB),
                BlendMode.modulate,
              )
            : const ColorFilter.mode(
                Colors.transparent,
                BlendMode.dst,
              ),
        child: Text(
          monogram,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  /// Two-letter monogram from the slug. Picks the first two alpha characters,
  /// uppercased; falls back to "PR" if nothing matches.
  String _monogramFor(String slug) {
    final letters = slug
        .replaceAll(RegExp(r'[^A-Za-z]'), '')
        .toUpperCase();
    if (letters.isEmpty) return 'PR';
    if (letters.length == 1) return letters + letters;
    return letters.substring(0, 2);
  }

  /// Stable gradient bucket from the slug — a tiny hash so the same project
  /// always gets the same colors across visits.
  List<Color> _gradientFor(String slug) {
    final int hash = slug.codeUnits.fold<int>(0, (int acc, int c) => acc + c);
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
    return palette[hash % palette.length];
  }
}

// ── Role badge ─────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final ProjectRole role;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (role) {
      ProjectRole.admin => AppColors.coral,
      ProjectRole.editor => AppColors.teal,
      ProjectRole.reader => AppColors.purple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.18),
        border: Border.all(color: accent.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            role.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Archived badge ─────────────────────────────────────────────

class _ArchivedBadge extends StatelessWidget {
  const _ArchivedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy.withOpacity(0.08),
        border: Border.all(color: AppColors.navy.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        'ARCHIVED',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.navy.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Counters strip ─────────────────────────────────────────────

class _Counters extends StatelessWidget {
  const _Counters({
    required this.toggles,
    required this.envs,
    required this.members,
    required this.isArchived,
  });

  final int toggles;
  final int envs;
  final int members;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    const Color borderColor = Color(0xFFDDD8CC);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
          bottom: BorderSide(color: borderColor, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Counter(
              value: toggles,
              label: 'Toggles',
              valueColor: isArchived
                  ? AppColors.navy.withOpacity(0.35)
                  : (toggles > 0 ? AppColors.green : AppColors.navy.withOpacity(0.3)),
            ),
          ),
          Expanded(
            child: _Counter(
              value: envs,
              label: 'Envs',
              valueColor: isArchived
                  ? AppColors.navy.withOpacity(0.35)
                  : AppColors.teal,
            ),
          ),
          Expanded(
            child: _Counter(
              value: members,
              label: 'Members',
              valueColor: isArchived
                  ? AppColors.navy.withOpacity(0.35)
                  : AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final int value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.navy.withOpacity(0.35),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ── Action button ──────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: () {
            // Stop propagation to the parent card so clicking the button
            // doesn't also open the project.
            widget.onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.accent.withOpacity(_hovering ? 0.26 : 0.16),
              border: Border.all(
                width: 2,
                color: widget.accent.withOpacity(_hovering ? 0.65 : 0.45),
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.accent,
            ),
          ),
        ),
      ),
    );
  }
}
