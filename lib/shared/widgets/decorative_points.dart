import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

class DecorativePoints extends StatelessWidget {
  final int count;
  const DecorativePoints({this.count = 5, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2 + (index * 0.1)),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ).animate(delay: (index * 100).ms)
         .fadeIn(duration: 600.ms)
         .slideX(begin: -4, end: 0, curve: Curves.easeOutBack, duration: 800.ms)
         .scale(begin: const Offset(0, 0), end: const Offset(1, 1));
      }),
    );
  }
}
