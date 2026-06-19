import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => GoogleFonts.interTextTheme(
    const TextTheme(
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
      displaySmall:  TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium:TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      titleSmall:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecond),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecond,  height: 1.5),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecond),
      labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textHint, letterSpacing: 0.5),
    ),
  );
}
