import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (!mounted) return;
    context.go(user != null ? '/home' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white, // Using white background for the green/gold logo to pop
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background decorative circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/yaqot_logo.svg',
                  width: 240,
                ).animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),

                const SizedBox(height: 40),

                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  strokeWidth: 3,
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),

            Positioned(
              bottom: 40,
              child: Text(
                'PREMIUM COLLECTIONS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 1, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}
