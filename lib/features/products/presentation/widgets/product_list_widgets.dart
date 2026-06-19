import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class ProductEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProductEmptyState({
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.primary.withOpacity(0.5)),
            ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecond,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductGridShimmer extends StatelessWidget {
  const ProductGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 80, color: AppColors.shimmerBase),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 40, color: AppColors.shimmerBase),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.4));
  }
}
