import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';

class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('PRIVACY'),
          _buildSelectionTile(
            title: 'Who can see my profile',
            value: settings['profile_visibility'] ?? 'Public',
            options: const ['Public', 'Followers', 'Private'],
            onChanged: (v) => notifier.setString('profile_visibility', v!),
          ),
          _buildSelectionTile(
            title: 'Who can message me',
            value: settings['message_permission'] ?? 'Everyone',
            options: const ['Everyone', 'Followers', 'No one'],
            onChanged: (v) => notifier.setString('message_permission', v!),
          ),
          _buildSelectionTile(
            title: 'Who can join my live streams',
            value: settings['live_join_permission'] ?? 'Everyone',
            options: const ['Everyone', 'Followers', 'Invited Only'],
            onChanged: (v) => notifier.setString('live_join_permission', v!),
          ),
          const Divider(height: 32),
          _buildSectionHeader('SECURITY'),
          ListTile(
            leading: const Icon(Icons.block, color: AppColors.error),
            title: const Text('Block List'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/blocked'),
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

  Widget _buildSelectionTile({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        onChanged: onChanged,
        items: options.map<DropdownMenuItem<String>>((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val),
          );
        }).toList(),
      ),
    );
  }
}
