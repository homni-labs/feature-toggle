import 'package:flutter/material.dart';

import 'package:togli_app/app/di/injection.dart';
import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:togli_app/features/environments/application/usecase/load_default_environments_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectDialogResult {
  final String slug;
  final String name;
  final String? description;

  /// Subset of platform default environments to bootstrap inside the new
  /// project. `null` means "use whatever the server treats as default", an
  /// empty list means "create no environments at all" (explicit opt-out),
  /// and a non-empty list bootstraps exactly those names. Always `null`
  /// for edit mode.
  final List<String>? environments;

  ProjectDialogResult({
    required this.slug,
    required this.name,
    this.description,
    this.environments,
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

  // Defaults loading state — only meaningful in create mode.
  bool _defaultsLoading = false;
  bool _defaultsFailed = false;
  List<String> _availableDefaults = const [];
  final Set<String> _selectedDefaults = <String>{};

  @override
  void initState() {
    super.initState();
    _slugController = TextEditingController();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descController =
        TextEditingController(text: widget.initialDescription ?? '');

    if (!widget.isEdit) {
      _loadDefaults();
    }
  }

  Future<void> _loadDefaults() async {
    setState(() {
      _defaultsLoading = true;
      _defaultsFailed = false;
    });
    final auth = context.read<AuthCubit>();
    final token = await auth.getValidAccessToken();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _defaultsLoading = false;
        _defaultsFailed = true;
      });
      return;
    }
    final result = await sl<LoadDefaultEnvironmentsUseCase>()(
      accessToken: token,
    );
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _defaultsLoading = false;
        _defaultsFailed = true;
        _availableDefaults = const [];
        _selectedDefaults.clear();
      }),
      (defaults) => setState(() {
        _defaultsLoading = false;
        _defaultsFailed = false;
        _availableDefaults = defaults;
        // Preselect everything — the common case is "I want all defaults".
        _selectedDefaults
          ..clear()
          ..addAll(defaults);
      }),
    );
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

    final String slug =
        widget.isEdit ? '' : _slugController.text.trim().toUpperCase();
    if (!widget.isEdit && slug.isEmpty) return;

    final String descText = _descController.text.trim();
    final String? description = descText.isEmpty ? null : descText;

    // Send exactly what the user has checked in the UI.
    List<String>? environments;
    if (!widget.isEdit) {
      environments = _selectedDefaults.toList();
      if (environments.isEmpty) environments = null;
    }

    Navigator.of(context).pop(ProjectDialogResult(
      slug: slug,
      name: name,
      description: description,
      environments: environments,
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
          color: const Color(0xFFFFFFFF),
          border: Border.all(color: AppColors.navy.withOpacity(0.12)),
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
                color: AppColors.navy,
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
                  color: AppColors.navy.withOpacity(0.3),
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

            // Default environments section (create mode only)
            if (!widget.isEdit) ...[
              const SizedBox(height: 18),
              _DefaultEnvironmentsSection(
                loading: _defaultsLoading,
                failed: _defaultsFailed,
                available: _availableDefaults,
                selected: _selectedDefaults,
                onToggle: (env) => setState(() {
                  if (_selectedDefaults.contains(env)) {
                    _selectedDefaults.remove(env);
                  } else {
                    _selectedDefaults.add(env);
                  }
                }),
              ),
            ],

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
                        foregroundColor: AppColors.navy.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: AppColors.navy.withOpacity(0.12),
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
        color: AppColors.navy.withOpacity(0.07),
        border: Border.all(color: AppColors.navy.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        style: const TextStyle(color: AppColors.navy, fontSize: 14),
        cursorColor: AppColors.coral,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.navy.withOpacity(0.3)),
          prefixIcon:
              Icon(icon, size: 20, color: AppColors.navy.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Default environments section ───────────────────────────────

class _DefaultEnvironmentsSection extends StatelessWidget {
  const _DefaultEnvironmentsSection({
    required this.loading,
    required this.failed,
    required this.available,
    required this.selected,
    required this.onToggle,
  });

  final bool loading;
  final bool failed;
  final List<String> available;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default environments',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.navy.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        if (loading)
          _buildHelperText('Loading defaults...')
        else if (failed)
          _buildHelperText(
            'Could not load defaults. Project will be created without environments — you can add them later.',
          )
        else if (available.isEmpty)
          _buildHelperText(
            'No default environments configured. You can add them after creating the project.',
          )
        else ...[
          _buildHelperText(
            'Pick which platform defaults to bootstrap. You can add custom environments later.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: available.map((env) {
              final isSelected = selected.contains(env);
              return GestureDetector(
                onTap: () => onToggle(env),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? _envColor(env).withOpacity(0.20)
                        : AppColors.navy.withOpacity(0.06),
                    border: Border.all(
                      color: isSelected
                          ? _envColor(env).withOpacity(0.5)
                          : AppColors.navy.withOpacity(0.12),
                    ),
                  ),
                  child: Text(
                    env,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? _envColor(env)
                          : AppColors.navy.withOpacity(0.4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildHelperText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: AppColors.navy.withOpacity(0.35),
      ),
    );
  }
}
