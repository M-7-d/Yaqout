import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

class CurvedBackground extends StatelessWidget {
  final double height;
  final Widget? child;
  final bool animate;

  const CurvedBackground({
    this.height = 200,
    this.child,
    this.animate = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Primary Curve
        ClipPath(
          clipper: _HeaderCurveClipper(),
          child: Container(
            height: height,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
        ).animate().slideY(
              begin: -1,
              end: 0,
              duration: 800.ms,
              curve: Curves.easeOutQuad,
            ),

        // Secondary Animated Curve
        ClipPath(
          clipper: _HeaderCurveClipper(),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.1),
                  AppColors.primaryDark.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).moveY(
          begin: 0,
          end: 15,
          duration: 3.seconds,
          curve: Curves.easeInOut,
        ),

        if (child != null) child!,
      ],
    );
  }
}

class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
