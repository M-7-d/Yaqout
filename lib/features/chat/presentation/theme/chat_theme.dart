import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Chat screen palette based on app primary colors.
class ChatTheme {
  ChatTheme._();

  static const headerBg = AppColors.primary;
  static const headerLight = AppColors.primaryDark;
  static const accent = AppColors.primary;
  static const accentDark = AppColors.primaryDark;

  static const wallpaper = AppColors.surface;
  static const sentBubble = AppColors.primaryLight;
  static const receivedBubble = AppColors.card;

  static const bubbleText = AppColors.textPrimary;
  static const metaText = AppColors.textHint;
  static const listSubtitle = AppColors.textHint;

  static const inputBar = AppColors.divider;
  static const inputField = AppColors.card;
  static const listBg = AppColors.card;
  static const unreadBadge = AppColors.primary;
  static const divider = AppColors.border;
  static const datePillText = AppColors.textSecond;

  static AppBarTheme appBarTheme({bool centerTitle = false}) => AppBarTheme(
        backgroundColor: headerBg,
        elevation: 0,
        centerTitle: centerTitle,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      );
}
