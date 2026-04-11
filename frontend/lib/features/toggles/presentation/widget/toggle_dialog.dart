import 'package:flutter/material.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class ToggleDialogResult {
  final String name;
  final String description;
  final List<String> environments;

  ToggleDialogResult({
    required this.name,
    required this.description,
    required this.environments,
  });
}

class ToggleDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final List<String>? initialEnvironments;
  final List<String> availableEnvironments;
  final bool isEdit;

  const ToggleDialog({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialEnvironments,
    required this.availableEnvironments,
    this.isEdit = false,
  });

  @override
  State<ToggleDialog> createState() => _ToggleDialogState();
}

class _ToggleDialogState extends State<ToggleDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late Set<String> _selectedEnvs;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descController =
        TextEditingController(text: widget.initialDescription ?? '');
    _selectedEnvs = Set<String>.from(widget.initialEnvironments ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(ToggleDialogResult(
      name: name,
      description: _descController.text.trim(),
      environments: _selectedEnvs.toList(),
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
                  widget.isEdit ? 'Edit Toggle' : 'Create Toggle',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                _buildField(
                  controller: _nameController,
                  hint: 'Toggle name',
                  icon: Icons.toggle_on_outlined,
                  autofocus: true,
                ),
                const SizedBox(height: 14),

                // Description
                _buildField(
                  controller: _descController,
                  hint: 'Description (optional)',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 18),

                // Environments
                Text(
                  'Environments',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEdit
                      ? 'Newly added envs start disabled — flip them on the toggle card.'
                      : 'New toggles start disabled in every env — flip them on after creating.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.navy.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.availableEnvironments.map((env) {
                    final selected = _selectedEnvs.contains(env);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedEnvs.remove(env);
                          } else {
                            _selectedEnvs.add(env);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: selected
                              ? _envColor(env).withOpacity(0.20)
                              : AppColors.navy.withOpacity(0.06),
                          border: Border.all(
                            color: selected
                                ? _envColor(env).withOpacity(0.5)
                                : AppColors.navy.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          env,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected
                                ? _envColor(env)
                                : AppColors.navy.withOpacity(0.4),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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

  Color _envColor(String env) {
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool autofocus = false,
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
