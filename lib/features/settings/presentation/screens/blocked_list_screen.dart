import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/blocked_users_provider.dart';

class BlockedListScreen extends ConsumerWidget {
  const BlockedListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsers = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: blockedUsers.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                final user = blockedUsers[index];
                return _buildBlockedUserCard(context, ref, user, index);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Blocked Users',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Users you block will appear here. You will not receive any messages or stream requests from them.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecond,
                  ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildBlockedUserCard(
      BuildContext context, WidgetRef ref, BlockedUser user, int index) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight,
              child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (_, __, ___) => Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
            const SizedBox(width: 14),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Unblock Button
            OutlinedButton(
              onPressed: () => _showUnblockConfirmation(context, ref, user),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Unblock',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
        delay: Duration(milliseconds: 50 * index), duration: 250.ms);
  }

  void _showUnblockConfirmation(
      BuildContext context, WidgetRef ref, BlockedUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(blockedUsersProvider.notifier)
                  .unblockUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.name} has been unblocked'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
