import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';

class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    final String profileVisibility = settings['profile_visibility'] ?? 'Public';
    final String messagePermission = settings['message_permission'] ?? 'Everyone';
    final String liveJoinPermission = settings['live_join_permission'] ?? 'Everyone';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // Premium SliverAppBar matching the style of Terms & About Us
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacy & Security',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3),
                        const SizedBox(height: 6),
                        Text(
                          'Manage your visibility and secure your account',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Settings Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Privacy Section
                  _buildSectionHeader('PRIVACY SETTINGS').animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSettingRow(
                          context: context,
                          ref: ref,
                          icon: Icons.visibility_outlined,
                          title: 'Profile Visibility',
                          subtitle: 'Control who can view your listed products, live sessions, and reviews.',
                          currentValue: profileVisibility,
                          prefKey: 'profile_visibility',
                          options: ['Public', 'Followers', 'Private'],
                          optionIcons: [
                            Icons.public_rounded,
                            Icons.people_alt_rounded,
                            Icons.lock_rounded
                          ],
                          optionDescriptions: [
                            'Anyone on Yakut can view your profile, items, and streams.',
                            'Only accounts that follow you can see your profile details.',
                            'Keep your account private. No one can see your profile without approval.'
                          ],
                        ),
                        const Divider(color: AppColors.divider, height: 1, indent: 56),
                        _buildSettingRow(
                          context: context,
                          ref: ref,
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Direct Messaging',
                          subtitle: 'Select who is permitted to send you direct chat messages.',
                          currentValue: messagePermission,
                          prefKey: 'message_permission',
                          options: ['Everyone', 'Followers', 'No one'],
                          optionIcons: [
                            Icons.forum_rounded,
                            Icons.people_alt_rounded,
                            Icons.chat_bubble_rounded
                          ],
                          optionDescriptions: [
                            'Any user can send you messages or start a deal conversation.',
                            'Only users you follow or who follow you can message you.',
                            'Disable direct messaging completely. No one can start new chats with you.'
                          ],
                        ),
                        const Divider(color: AppColors.divider, height: 1, indent: 56),
                        _buildSettingRow(
                          context: context,
                          ref: ref,
                          icon: Icons.live_tv_rounded,
                          title: 'Live Join Permission',
                          subtitle: 'Restrict access to who can view or join your live streams.',
                          currentValue: liveJoinPermission,
                          prefKey: 'live_join_permission',
                          options: ['Everyone', 'Followers', 'Invited Only'],
                          optionIcons: [
                            Icons.people_rounded,
                            Icons.people_outline_rounded,
                            Icons.vpn_key_rounded
                          ],
                          optionDescriptions: [
                            'Anyone on the marketplace can view your live broadcasts.',
                            'Only users following you are notified and allowed to join.',
                            'Only users with direct links or invitations can watch your broadcast.'
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // Premium Security Tip Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryLight.withOpacity(0.4),
                          AppColors.primaryLight.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Keep your account secure',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Yakut support will never ask you for your account password or SMS verification codes. Keep your login details private.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecond,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String subtitle,
    required String currentValue,
    required String prefKey,
    required List<String> options,
    required List<IconData> optionIcons,
    required List<String> optionDescriptions,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecond, fontSize: 13, height: 1.4),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentValue,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.unfold_more_rounded, size: 16, color: AppColors.primary),
          ],
        ),
      ),
      onTap: () => _showSelectionBottomSheet(
        context: context,
        ref: ref,
        title: title,
        prefKey: prefKey,
        currentValue: currentValue,
        options: options,
        optionIcons: optionIcons,
        optionDescriptions: optionDescriptions,
      ),
    );
  }

  void _showSelectionBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String prefKey,
    required String currentValue,
    required List<String> options,
    required List<IconData> optionIcons,
    required List<String> optionDescriptions,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bottom Sheet Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.divider, height: 1),
                ),
                
                // Options List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == currentValue;
                    final icon = optionIcons[index];
                    final description = optionDescriptions[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? AppColors.primary : AppColors.textSecond,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        option,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecond,
                            height: 1.4,
                          ),
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                            )
                          : null,
                      onTap: () {
                        ref.read(settingsNotifierProvider.notifier).setString(prefKey, option);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
