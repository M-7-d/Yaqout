import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Account Section
          _buildSectionHeader(context, 'Account'),
          Card(
            elevation: 0,
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user.avatarUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              errorWidget: (_, __, ___) => Text(
                                user.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User Name',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          user?.email ?? 'email@example.com',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecond,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings/edit-profile'),
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (user?.isSeller == true) ...[
            _buildSectionHeader(context, 'My Shop'),
            _buildSettingTile(
              context,
              icon: Icons.storefront_outlined,
              title: 'View My Shop',
              onTap: () => context.push('/sellers/${user!.id}'),
            ),
            _buildSettingTile(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'Manage My Products',
              onTap: () => context.push('/settings/manage-products'),
            ),
            const SizedBox(height: 24),
          ] else ...[
            _buildSectionHeader(context, 'Seller Account'),
            _buildSettingTile(
              context,
              icon: Icons.storefront_outlined,
              title: 'Become a Seller',
              subtitle: 'Start selling your products today',
              onTap: () => context.push('/settings/become-seller'),
            ),
            const SizedBox(height: 24),
          ],

          _buildSectionHeader(context, 'Notifications'),
          _buildSettingTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Notification Settings',
            onTap: () => context.push('/settings/notifications'),
          ),
          const SizedBox(height: 24),

          // 3. Privacy & Security
          _buildSectionHeader(context, 'Privacy & Security'),
          _buildSettingTile(
            context,
            icon: Icons.security_outlined,
            title: 'Privacy Settings',
            onTap: () => context.push('/settings/privacy'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.delete_outline_rounded,
            title: 'Delete Account',
            titleColor: AppColors.error,
            onTap: () => _showDeleteAccountConfirmation(context),
          ),
          const SizedBox(height: 24),

          // 4. Support & About
          _buildSectionHeader(context, 'Support & About'),
          _buildSettingTile(
            context,
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            onTap: () => context.push('/settings/report-bug'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'Support Center',
            onTap: () => context.push('/settings/support'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'About Us',
            onTap: () => context.push('/settings/about'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              // Usually open a URL
            },
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text(
                'Logout',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete logic
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: titleColor ?? AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
