import 'dart:async';
import 'package:flutter/material.dart';
import 'package:feature_toggle_app/features/auth/domain/model/user.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class AddMemberDialogResult {
  final String userId;
  final ProjectRole role;

  AddMemberDialogResult({
    required this.userId,
    required this.role,
  });
}

class AddMemberDialog extends StatefulWidget {
  final Future<List<User>> Function(String query) onSearch;

  const AddMemberDialog({super.key, required this.onSearch});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  late TextEditingController _searchController;
  ProjectRole _selectedRole = ProjectRole.reader;
  User? _selectedUser;
  List<User> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _searching = true);
    try {
      final List<User> results = await widget.onSearch(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  void _selectUser(User user) {
    setState(() {
      _selectedUser = user;
      _searchController.text = user.displayName;
      _searchResults = [];
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUser = null;
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _submit() {
    if (_selectedUser == null) return;
    Navigator.of(context).pop(AddMemberDialogResult(
      userId: _selectedUser!.id.value,
      role: _selectedRole,
    ));
  }

  static Color _roleColor(ProjectRole role) {
    switch (role) {
      case ProjectRole.admin:
        return AppColors.coral;
      case ProjectRole.editor:
        return AppColors.teal;
      case ProjectRole.reader:
        return AppColors.purple;
    }
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
            const Text(
              'Add Member',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Search field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.07),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                enabled: _selectedUser == null,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: AppColors.coral,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by email or name...',
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: Colors.white.withOpacity(0.4)),
                  suffixIcon: _selectedUser != null
                      ? GestureDetector(
                          onTap: _clearSelection,
                          child: Icon(Icons.close_rounded,
                              size: 18,
                              color: Colors.white.withOpacity(0.4)),
                        )
                      : _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.coral,
                                ),
                              ),
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Search results dropdown
            if (_searchResults.isNotEmpty && _selectedUser == null) ...[
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF252848),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _searchResults.length,
                  itemBuilder: (BuildContext context, int index) {
                    final User user = _searchResults[index];
                    return _SearchResultItem(
                      user: user,
                      onTap: () => _selectUser(user),
                    );
                  },
                ),
              ),
            ],

            // Selected user info
            if (_selectedUser != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.teal.withOpacity(0.1),
                  border:
                      Border.all(color: AppColors.teal.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 18, color: AppColors.teal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedUser!.displayName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                          Text(
                            _selectedUser!.email.value,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Role selector label
            Text(
              'Role',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 10),

            // Role chips
            Row(
              children:
                  ProjectRole.values.map((ProjectRole role) {
                final bool selected = _selectedRole == role;
                final Color color = _roleColor(role);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRole = role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: selected
                            ? color.withOpacity(0.20)
                            : Colors.white.withOpacity(0.06),
                        border: Border.all(
                          color: selected
                              ? color.withOpacity(0.5)
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        role.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? color
                              : Colors.white.withOpacity(0.4),
                        ),
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
                        foregroundColor:
                            Colors.white.withOpacity(0.6),
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
                      onPressed:
                          _selectedUser != null ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.coral.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Add'),
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
}

// ── Search result item ─────────────────────────────────────────

class _SearchResultItem extends StatefulWidget {
  final User user;
  final VoidCallback onTap;

  const _SearchResultItem({required this.user, required this.onTap});

  @override
  State<_SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<_SearchResultItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: _hovering
              ? Colors.white.withOpacity(0.06)
              : Colors.transparent,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.teal.withOpacity(0.2),
                child: Text(
                  widget.user.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.user.email.value,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.35),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
