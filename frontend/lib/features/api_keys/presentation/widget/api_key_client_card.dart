import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key_client.dart';

class ApiKeyClientCard extends StatelessWidget {
  final ApiKeyClient client;
  const ApiKeyClientCard({super.key, required this.client});

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

  Color _statusColor() {
    if (client.isActive) return AppColors.green;
    if (client.isRecent) return AppColors.yellow;
    return const Color(0xFFBBBBBB);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final isSdk = client.clientType == ClientType.sdk;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service name + status dot
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: client.isActive
                        ? [
                            BoxShadow(
                              color: statusColor.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    client.serviceName,
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Badges row
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (client.namespace != null)
                  _ClientBadge(
                    label: client.namespace!,
                    color: AppColors.navy.withOpacity(0.5),
                    bgColor: AppColors.navy.withOpacity(0.06),
                  ),
                _ClientBadge(
                  label: isSdk
                      ? (client.sdkName ?? 'SDK')
                      : 'REST',
                  color: isSdk ? AppColors.teal : AppColors.purple,
                  bgColor: isSdk
                      ? AppColors.teal.withOpacity(0.1)
                      : AppColors.purple.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Divider
            Container(
              height: 2,
              color: const Color(0xFFDDD8CC),
            ),
            const SizedBox(height: 12),

            // Meta row
            Row(
              children: [
                _ClientMeta(
                  label: 'First seen',
                  value: _formatDate(client.firstSeenAt),
                ),
                const SizedBox(width: 16),
                _ClientMeta(
                  label: 'Last seen',
                  value: _formatTimeAgo(client.lastSeenAt),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Requests',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.navy.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCount(client.requestCount),
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }
}

class _ClientBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _ClientBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: bgColor,
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

class _ClientMeta extends StatelessWidget {
  final String label;
  final String value;

  const _ClientMeta({required this.label, required this.value});

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
