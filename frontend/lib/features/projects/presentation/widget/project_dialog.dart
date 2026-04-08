import 'package:flutter/material.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class ProjectDialogResult {
  final String slug;
  final String name;
  final String? description;

  ProjectDialogResult({
    required this.slug,
    required this.name,
    this.description,
  });
}

class ProjectDialog extends StatefulWidget {
  final bool isEdit;
  final String? initialName;
  final String? initialDescription;

  const ProjectDialog({
    super.key,
    this.isEdit = false,
    this.initialName,
    this.initialDescription,
  });

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  late TextEditingController _slugController;
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _slugController = TextEditingController();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descController =
        TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _slugController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;

    final String slug = widget.isEdit ? '' : _slugController.text.trim().toUpperCase();
    if (!widget.isEdit && slug.isEmpty) return;

    final String descText = _descController.text.trim();
    final String? description = descText.isEmpty ? null : descText;

    Navigator.of(context).pop(ProjectDialogResult(
      slug: slug,
      name: name,
      description: description,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF1E2040),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEdit ? 'Edit Project' : 'Create Project',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Slug field (only for create)
            if (!widget.isEdit) ...[
              _buildField(
                controller: _slugController,
                hint: 'Project slug (e.g. HOMNI)',
                icon: Icons.tag_rounded,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              Text(
                '2-50 chars, letters, digits, hyphens',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Name field
            _buildField(
              controller: _nameController,
              hint: 'Project name',
              icon: Icons.folder_outlined,
              autofocus: widget.isEdit,
            ),
            const SizedBox(height: 14),

            // Description field
            _buildField(
              controller: _descController,
              hint: 'Description (optional)',
              icon: Icons.notes_rounded,
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(widget.isEdit ? 'Save' : 'Create'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool autofocus = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: AppColors.coral,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon:
              Icon(icon, size: 20, color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
