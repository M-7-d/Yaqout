import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/verify_code_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/products/presentation/screens/home_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/product_form_screen.dart';
import '../../features/products/presentation/screens/manage_products_screen.dart';
import '../../features/products/presentation/screens/seller_profile_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/chat/presentation/screens/chat_start_from_product_screen.dart';
import '../../features/live_stream/presentation/screens/live_list_screen.dart';
import '../../features/live_stream/presentation/screens/live_stream_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/seller_profile_edit_screen.dart';
import '../../features/settings/presentation/screens/notification_settings_screen.dart';
import '../../features/settings/presentation/screens/privacy_security_screen.dart';
import '../../features/settings/presentation/screens/support_screen.dart';
import '../../features/settings/presentation/screens/blocked_list_screen.dart';
import '../../features/settings/presentation/screens/become_seller_screen.dart';
import '../../features/settings/presentation/screens/about_us_screen.dart';
import '../../features/settings/presentation/screens/report_bug_screen.dart';
import '../../features/settings/presentation/screens/terms_conditions_screen.dart';
import '../../shared/widgets/main_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final isLoading  = authNotifier.isLoading;
      final isLoggedIn = authNotifier.valueOrNull != null;
      final path       = state.matchedLocation;

      if (isLoading) { return null; }
      if (!isLoggedIn && path != '/splash' &&
          !path.startsWith('/auth')) { return '/auth/login'; }
      if (isLoggedIn && path.startsWith('/auth')) { return '/home'; }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (_, __) => _fade(const SplashScreen()),
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        pageBuilder: (_, __) => _fade(const LoginScreen()),
      ),
      GoRoute(
        path: '/auth/register',
        pageBuilder: (_, __) => _fade(const RegisterScreen()),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (_, s) => _slide(const ForgotPasswordScreen()),
        routes: [
          GoRoute(
            path: 'reset',
            pageBuilder: (_, __) => _slide(const ResetPasswordScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/auth/verify',
        pageBuilder: (_, state) => _slide(
          VerifyCodeScreen(
            email: state.uri.queryParameters['email'] ?? '',
            isSignUp: state.uri.queryParameters['type'] == 'signup',
          ),
        ),
      ),

      // ── Main shell with bottom nav ─────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => _fade(const HomeScreen()),
          ),
            GoRoute(
            path: '/live',
            pageBuilder: (_, __) => _fade(const LiveListScreen()),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (_, __) => _fade(const ChatListScreen()),
          ),
        
          GoRoute(
            path: '/settings',
            pageBuilder: (_, __) => _fade(const SettingsScreen()),
          ),
        ],
      ),

      // ── Fullscreen routes (no bottom nav) ─────────────────────────────────
      // Static `/products/new` must be registered before `/products/:id`, or
      // "new" is captured as a product id and the detail screen errors.
      GoRoute(
        path: '/products/new',
        pageBuilder: (_, __) => _slide(const ProductFormScreen()),
      ),
      GoRoute(
        path: '/products/:id/edit',
        pageBuilder: (_, s) => _slide(
          ProductFormScreen(productId: s.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/products/:id',
        pageBuilder: (_, s) => _slide(
          ProductDetailScreen(productId: s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/sellers/:id',
        pageBuilder: (_, s) => _slide(
          SellerProfileScreen(sellerId: s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/chat/new',
        pageBuilder: (ctx, state) {
          final q = state.uri.queryParameters;
          return _slide(
            ChatStartFromProductScreen(
              sellerId: q['sellerId'] ?? '',
              buyerId: q['buyerId'] ?? '',
              productId: q['productId'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/chat/:roomId',
        pageBuilder: (_, s) => _slide(
          ChatRoomScreen(roomId: s.pathParameters['roomId']!),
        ),
      ),
      GoRoute(
        path: '/live/:streamId',
        pageBuilder: (_, s) => _fade(
          LiveStreamScreen(streamId: s.pathParameters['streamId']!),
        ),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        pageBuilder: (_, __) => _slide(const EditProfileScreen()),
      ),
      GoRoute(
        path: '/settings/edit-seller-profile',
        pageBuilder: (_, __) => _slide(const SellerProfileEditScreen()),
      ),
      GoRoute(
        path: '/settings/become-seller',
        pageBuilder: (_, __) => _slide(const BecomeSellerScreen()),
      ),
      GoRoute(
        path: '/settings/notifications',
        pageBuilder: (_, __) => _slide(const NotificationSettingsScreen()),
      ),
      GoRoute(
        path: '/settings/privacy',
        pageBuilder: (_, __) => _slide(const PrivacySecurityScreen()),
      ),
      GoRoute(
        path: '/settings/blocked',
        pageBuilder: (_, __) => _slide(const BlockedListScreen()),
      ),
      GoRoute(
        path: '/settings/support',
        pageBuilder: (_, __) => _slide(const SupportScreen()),
      ),
      GoRoute(
        path: '/settings/about',
        pageBuilder: (_, __) => _slide(const AboutUsScreen()),
      ),
      GoRoute(
        path: '/settings/report-bug',
        pageBuilder: (_, __) => _slide(const ReportBugScreen()),
      ),
      GoRoute(
        path: '/settings/terms',
        pageBuilder: (_, __) => _slide(const TermsConditionsScreen()),
      ),
      GoRoute(
        path: '/settings/manage-products',
        pageBuilder: (_, __) => _slide(const ManageProductsScreen()),
      ),
    ],
  );
});

// ── Page transition helpers ────────────────────────────────────────────────────
CustomTransitionPage<void> _fade(Widget child) => CustomTransitionPage(
      child: child,
      transitionsBuilder: (_, anim, __, c) =>
          FadeTransition(opacity: anim, child: c),
    );

CustomTransitionPage<void> _slide(Widget child) => CustomTransitionPage(
      child: child,
      transitionsBuilder: (_, anim, __, c) => SlideTransition(
        position: anim.drive(
          Tween(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOutCubic)),
        ),
        child: c,
      ),
    );

// Makes GoRouter re-evaluate redirect when auth state changes
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}
