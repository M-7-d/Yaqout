import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Blue Palette
  static const blue50  = Color(0xFFEAF0FB);
  static const blue100 = Color(0xFFC4D4F3);
  static const blue200 = Color(0xFFA8C0ED);
  static const blue300 = Color(0xFF789DE3);
  static const blue400 = Color(0xFF5182DB);
  static const blue500 = Color(0xFF2B66D4);
  static const blue600 = Color(0xFF2454AE);
  static const blue700 = Color(0xFF1C4187);
  static const blue800 = Color(0xFF142F61);
  static const blue900 = Color(0xFF0C1D3B);
  static const blue950 = Color(0xFF040A15);

  static const primary      = blue500;
  static const primaryDark  = blue700;
  static const primaryLight = blue50;

  static const accent       = blue400;
  static const accentLight  = blue100;
  static const accentDark   = blue600;

  static const surface      = Color(0xFFFBFDFA);
  static const card         = Color(0xFFFFFFFF);
  static const border       = Color(0xFFE8EDE9);
  static const divider      = Color(0xFFF0F4F1);

  static const textPrimary  = blue950;
  static const textSecond   = blue800;
  static const textHint     = Color(0xFF9EAEA4);

  static const success      = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const warning      = Color(0xFFFBC02D);
  static const warningLight = Color(0xFFFFF9C4);
  static const error        = Color(0xFFD32F2F);
  static const errorLight   = Color(0xFFFFEBEE);

  static const shimmerBase  = Color(0xFFE8EDE9);
  static const shimmerHigh  = Color(0xFFF5F9F6);

  static const gradientStart = blue500;
  static const gradientEnd   = blue300;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [blue300, blue500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
