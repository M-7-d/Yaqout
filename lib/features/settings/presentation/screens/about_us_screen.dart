import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
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
                    bottom: 40,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yakut',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.5),
                        const SizedBox(height: 8),
                        Text(
                          'Your Next Generation Marketplace',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Our Mission').animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 12),
                  _buildText(
                    'At Yakut, our mission is to empower sellers and buyers to connect in a vibrant, '
                    'real-time marketplace. We believe in building trust through transparency, '
                    'live interactions, and a seamless shopping experience.'
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Our Story').animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 12),
                  _buildText(
                    'What started as a simple idea has blossomed into a full-fledged ecosystem. '
                    'We noticed that traditional e-commerce lacked the personal touch of a physical store. '
                    'That\'s why we integrated live streaming directly into the shopping journey—bringing '
                    'the human element back to digital commerce.'
                  ).animate().fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Core Values').animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 16),
                  _buildValueCard(
                    Icons.favorite_rounded,
                    'Community First',
                    'We prioritize the safety and satisfaction of our community members.',
                  ).animate().fadeIn(delay: 800.ms).slideX(),
                  const SizedBox(height: 12),
                  _buildValueCard(
                    Icons.lightbulb_rounded,
                    'Innovation',
                    'We constantly iterate to provide cutting-edge live commerce tools.',
                  ).animate().fadeIn(delay: 900.ms).slideX(),
                  const SizedBox(height: 12),
                  _buildValueCard(
                    Icons.verified_rounded,
                    'Trust & Quality',
                    'A secure platform where authenticity is always guaranteed.',
                  ).animate().fadeIn(delay: 1000.ms).slideX(),

                  const SizedBox(height: 48),

                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Get in Touch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'support@yakut.app',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialIcon(Icons.camera_alt_outlined),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.tag),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.language),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Text(
                          '© ${DateTime.now().year} Yakut. All rights reserved.',
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ).animate().fadeIn(delay: 1200.ms),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.6,
        color: AppColors.textSecond,
      ),
    );
  }

  Widget _buildValueCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 20),
    );
  }
}
