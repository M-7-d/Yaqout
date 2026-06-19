import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../features/live_stream/presentation/providers/stream_provider.dart';
import '../../features/products/presentation/providers/follow_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({required this.child, super.key});

  static const _tabs = ['/home', '/live', '/chat', '/settings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(liveStreamsProvider, (previous, next) {
      if (next is AsyncData) {
        final currentStreams = next.value ?? [];
        final previousStreams = previous?.valueOrNull ?? [];
        
        final followedSellers = ref.read(followedSellersProvider);
        
        for (final stream in currentStreams) {
          if (!previousStreams.any((s) => s.id == stream.id) && followedSellers.contains(stream.sellerId)) {
            // New stream from followed seller
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎥 ${stream.sellerName ?? 'A seller you follow'} is now live: ${stream.title}'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Watch',
                  onPressed: () => context.push('/live/${stream.id}'),
                ),
              ),
            );
          }
        }
      }
    });

    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t));

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: idx < 0 ? 0 : idx,
          backgroundColor: AppColors.card,
          indicatorColor: AppColors.primaryLight,
          elevation: 0,
          onDestinationSelected: (i) => context.go(_tabs[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: AppStrings.home,
            ),
                        NavigationDestination(
              icon: Icon(Icons.live_tv_outlined),
              selectedIcon: Icon(Icons.live_tv_rounded, color: AppColors.primary),
              label: AppStrings.liveTab,
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
              label: 'Chats',
            ),

            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
              label: AppStrings.settings,
            ),
          ],
        ),
      ),
    );
  }
}
