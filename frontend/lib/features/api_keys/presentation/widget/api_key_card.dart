import 'package:flutter/material.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key.dart';
import 'package:togli_app/core/domain/value_objects/project_role.dart';
import 'package:togli_app/app/theme/app_colors.dart';

class ApiKeyCard extends StatelessWidget {
  final ApiKey apiKey;
  final VoidCallback? onRevoke;
  final VoidCallback? onDelete;
  final VoidCallback? onViewClients;

  const ApiKeyCard({
    super.key,
    required this.apiKey,
    this.onRevoke,
    this.onDelete,
    this.onViewClients,
  });

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

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = _roleColor(apiKey.role);
    final bool isRevoked = !apiKey.active;

    return Opacity(
      opacity: isRevoked ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: AppColors.navy, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFDDD8CC),
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Status dot
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRevoked
                      ? const Color(0xFFDDD8CC)
                      : AppColors.green,
                  boxShadow: isRevoked
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.green.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                ),
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Text(
                      apiKey.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isRevoked
                            ? AppColors.navy.withOpacity(0.5)
                            : AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Masked token
                  Text(
                    apiKey.maskedToken,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.navy.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badges
                  Row(
                    children: [
                      _Badge(
                        label: apiKey.roleLabel,
                        color: roleColor,
                      ),
                      if (isRevoked) ...[
                        const SizedBox(width: 6),
                        const _Badge(
                          label: 'Revoked',
                          color: AppColors.coral,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Divider + meta
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFDDD8CC),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _MetaColumn(
                          label: 'Created',
                          value: _formatDate(apiKey.createdAt),
                        ),
                        const SizedBox(width: 16),
                        _MetaColumn(
                          label: isRevoked ? 'Revoked' : 'Expires',
                          value: apiKey.expiresAt != null
                              ? _formatDate(apiKey.expiresAt!)
                              : 'No expiry',
                        ),
                        const Spacer(),
                        if (!isRevoked && onRevoke != null)
                          _RevokeButton(onTap: onRevoke!),
                        if (isRevoked && onDelete != null)
                          _DeleteButton(onTap: onDelete!),
                      ],
                    ),
                  ),

                  // Usage info
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    margin: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFDDD8CC),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            apiKey.lastUsedAt != null
                                ? 'Last used: ${_formatTimeAgo(apiKey.lastUsedAt!)}'
                                : 'Never used',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.navy.withOpacity(0.45),
                            ),
                          ),
                        ),
                        _ServicesLink(
                          count: apiKey.clientCount ?? 0,
                          onTap: onViewClients,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetaColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.navy.withOpacity(0.45),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.navy.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _RevokeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RevokeButton({required this.onTap});

  @override
  State<_RevokeButton> createState() => _RevokeButtonState();
}

class _RevokeButtonState extends State<_RevokeButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: _hovering
                ? AppColors.coral.withOpacity(0.12)
                : AppColors.coral.withOpacity(0.06),
            border: Border.all(
              color: AppColors.coral.withOpacity(0.35),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.block_rounded,
            size: 14,
            color: AppColors.coral,
          ),
        ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: _hovering
                ? AppColors.coral.withOpacity(0.12)
                : AppColors.coral.withOpacity(0.06),
            border: Border.all(
              color: AppColors.coral.withOpacity(0.35),
              width: 2,
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

class _ServicesLink extends StatefulWidget {
  final int count;
  final VoidCallback? onTap;
  const _ServicesLink({required this.count, this.onTap});

  @override
  State<_ServicesLink> createState() => _ServicesLinkState();
}

class _ServicesLinkState extends State<_ServicesLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.count > 0
        ? '${widget.count} ${widget.count == 1 ? 'service' : 'services'}'
        : 'No services';

    if (widget.onTap == null || widget.count == 0) {
      return Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.navy.withOpacity(0.35),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.coral,
            decoration:
                _hovering ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.coral,
          ),
        ),
      ),
    );
  }
}
