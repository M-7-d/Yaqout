import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Master switch for all notifications',
            value: settings['push_notifications'] ?? true,
            onChanged: (v) => notifier.setBool('push_notifications', v),
          ),
          const Divider(height: 32),
          _buildSectionHeader('ACTIVITY'),
          _buildSwitchTile(
            title: 'Live Stream Notifications',
            subtitle: 'Get notified when followed creators go live',
            value: settings['live_stream_notifications'] ?? true,
            onChanged: (v) => notifier.setBool('live_stream_notifications', v),
          ),
          _buildSwitchTile(
            title: 'New Followers',
            subtitle: 'When someone starts following you',
            value: settings['new_followers'] ?? true,
            onChanged: (v) => notifier.setBool('new_followers', v),
          ),
          _buildSwitchTile(
            title: 'Likes & Comments',
            subtitle: 'Activity on your products and posts',
            value: settings['likes_comments'] ?? true,
            onChanged: (v) => notifier.setBool('likes_comments', v),
          ),
          _buildSwitchTile(
            title: 'Ratings & Reviews',
            subtitle: 'When someone rates or reviews your product',
            value: settings['ratings_reviews'] ?? true,
            onChanged: (v) => notifier.setBool('ratings_reviews', v),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('MESSAGES'),
          _buildSwitchTile(
            title: 'Messages / Chat',
            subtitle: 'New direct messages and group chats',
            value: settings['messages_chat'] ?? true,
            onChanged: (v) => notifier.setBool('messages_chat', v),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('SYSTEM'),
          _buildSwitchTile(
            title: 'In-App Sounds / Vibration',
            subtitle: 'Sounds and haptics while using the app',
            value: settings['in_app_sounds'] ?? true,
            onChanged: (v) => notifier.setBool('in_app_sounds', v),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
