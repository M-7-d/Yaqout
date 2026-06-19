import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/stream_provider.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../products/presentation/widgets/product_search_delegate.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class LiveListScreen extends ConsumerWidget {
  const LiveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveStreams = ref.watch(liveStreamsProvider);
    final upcoming   = ref.watch(upcomingStreamsProvider);
    final user       = ref.watch(authNotifierProvider).valueOrNull;
    final unreadCount = user != null ? ref.watch(unreadCountProvider(user.id)) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Streams'),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(),
              );
            },
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search products',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Live now ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('Live Now',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          ),

          liveStreams.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text(e.toString()))),
            data: (list) => list.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.live_tv_outlined,
                                size: 56, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text('No live streams right now',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecond)),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _StreamCard(
                            stream: list[i], isLive: true, index: i),
                        childCount: list.length,
                      ),
                    ),
                  ),
          ),

          // ── Upcoming ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Upcoming',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),

          upcoming.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text(e.toString()))),
            data: (list) => list.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No upcoming streams',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecond)),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _StreamCard(
                            stream: list[i], isLive: false, index: i),
                        childCount: list.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),

      // Go live FAB for sellers
      floatingActionButton: user?.isSeller == true
          ? FloatingActionButton.extended(
              onPressed: () => _showGoLiveDialog(context, ref, user!.id),
              backgroundColor: AppColors.error,
              icon: const Icon(Icons.live_tv_rounded, color: Colors.white),
              label: const Text('Go Live',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Future<void> _showGoLiveDialog(
      BuildContext context, WidgetRef ref, String sellerId) async {
    final titleCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a Live Stream'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Stream title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final stream = await ref
                  .read(streamRepositoryProvider)
                  .createStream(
                    sellerId: sellerId,
                    title:    titleCtrl.text.trim(),
                  );
              if (context.mounted) {
                context.push('/live/${stream.id}');
              }
            },
            child: const Text('Go Live'),
          ),
        ],
      ),
    );
  }
}

class _StreamCard extends ConsumerWidget {
  final LiveStreamEntity stream;
  final bool isLive;
  final int index;
  const _StreamCard({
    required this.stream,
    required this.isLive,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(userByIdProvider(stream.sellerId));

    return GestureDetector(
      onTap: () => context.push('/live/${stream.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Thumbnail placeholder / Seller avatar
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: sellerAsync.when(
                data: (user) => user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(
                              Icons.live_tv_rounded,
                              color: Colors.white,
                              size: 30),
                        ),
                      )
                    : const Icon(Icons.live_tv_rounded,
                        color: Colors.white, size: 30),
                loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                error: (_, __) => const Icon(Icons.live_tv_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      if (isLive) const SizedBox(width: 8),
                      Expanded(
                        child: Text(stream.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  sellerAsync.when(
                    data: (user) => Text(
                      user?.fullName ?? stream.sellerName ?? 'Seller',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecond),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => Text(
                      stream.sellerName ?? 'Seller',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecond),
                    ),
                  ),
                  if (isLive) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text('${stream.viewerCount} watching',
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ).animate().fadeIn(
          delay: Duration(milliseconds: 60 * index), duration: 300.ms),
    );
  }
}



