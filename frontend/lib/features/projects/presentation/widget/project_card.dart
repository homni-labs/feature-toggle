import 'package:flutter/material.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onArchive,
    this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1E2040),
          border: Border.all(
            color: project.archived
                ? Colors.white.withOpacity(0.08)
                : AppColors.teal.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Key badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.coral.withOpacity(0.2),
                ),
                child: Text(
                  project.slug.value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.coral,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (project.description != null &&
                        project.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        project.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.35),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Archived badge
              if (project.archived) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: Text(
                    'Archived',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Archive button
              if (onArchive != null) ...[
                _ActionButton(
                  icon: Icons.archive_outlined,
                  onTap: onArchive!,
                ),
                const SizedBox(width: 4),
              ],

              // Unarchive button
              if (onUnarchive != null)
                _ActionButton(
                  icon: Icons.unarchive_outlined,
                  onTap: onUnarchive!,
                ),
            ],
          ),
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
