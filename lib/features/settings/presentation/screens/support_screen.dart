import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Support'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'How can we help you?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Choose an option below to get started',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecond,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 48),

            // Options
            _buildActionCard(
              context,
              icon: Icons.menu_book_rounded,
              title: 'Help Center / FAQ',
              subtitle: 'Find answers to frequently asked questions',
              onTap: () {},
              delay: 400,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Contact Support',
              subtitle: 'Chat directly with our support team',
              onTap: () {},
              delay: 500,
            ),
            const SizedBox(height: 48),

            const Center(
              child: Text(
                'Version v1.2.3',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryLight, size: 18),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideX(),
    );
  }
}
