import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';

class YakutApp extends ConsumerWidget {
  const YakutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Yakoot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)), // premium blue
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Inter'),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white, size: 24),
          actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      routerConfig: router,
    );
  }
}
