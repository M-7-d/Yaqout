import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/chat_search_delegate.dart';
import '../theme/chat_theme.dart';
import '../../domain/entities/chat_entities.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  String _relativeDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final date = dateTime.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return DateFormat('HH:mm').format(date);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    if (date.year == now.year) return DateFormat('d/M/yy').format(date);
    return DateFormat('d/M/yy').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final rooms = user != null
        ? ref.watch(userRoomsProvider(user.id))
        : const AsyncValue.data([]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: ChatTheme.headerBg,
      ),
      child: Scaffold(
        backgroundColor: ChatTheme.listBg,
        appBar: AppBar(
          backgroundColor: ChatTheme.headerBg,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Chats',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                if (user == null) return;
                showSearch(
                  context: context,
                  delegate: ChatSearchDelegate(user.id),
                );
              },
              icon: const Icon(Icons.search, color: Colors.white),
              tooltip: 'Search',
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: rooms.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: ChatTheme.accent),
          ),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (list) {
            final typedList = list.cast<ChatRoomEntity>();
            return typedList.isEmpty
                ? _buildEmptyState(context)
                : _buildChatList(context, typedList, user?.id);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: ChatTheme.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: ChatTheme.accent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: ChatTheme.bubbleText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start chatting by messaging a seller',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ChatTheme.listSubtitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(
    BuildContext context,
    List<ChatRoomEntity> list,
    String? userId,
  ) {
    final sorted = List<ChatRoomEntity>.from(list);
    sorted.sort((a, b) {
      final aDate = a.lastMessageAt ?? a.createdAt;
      final bDate = b.lastMessageAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.5,
        indent: 78,
        color: ChatTheme.divider,
      ),
      itemBuilder: (ctx, i) {
        final room = sorted[i];
        final isUnread = room.unreadCount > 0;
        final other = userId == room.buyerId
            ? room.sellerName ?? 'Seller'
            : room.buyerName ?? 'Buyer';
        final otherName = room.otherUserName ?? other;
        final dateStr = _relativeDate(room.lastMessageAt ?? room.createdAt);

        return _ChatListTile(
          room: room,
          otherName: otherName,
          dateStr: dateStr,
          isUnread: isUnread,
        );
      },
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final ChatRoomEntity room;
  final String otherName;
  final String dateStr;
  final bool isUnread;

  const _ChatListTile({
    required this.room,
    required this.otherName,
    required this.dateStr,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/chat/${room.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: ChatTheme.divider,
              child: (room.otherUserAvatar != null &&
                      room.otherUserAvatar!.isNotEmpty)
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: room.otherUserAvatar!,
                        width: 52,
                        height: 52,
                        memCacheWidth: 104,
                        memCacheHeight: 104,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => _avatarFallback(),
                      ),
                    )
                  : _avatarFallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.w500,
                            color: ChatTheme.bubbleText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread
                              ? ChatTheme.accent
                              : ChatTheme.listSubtitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: room.lastMessage != null
                            ? Text(
                                room.lastMessage!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.3,
                                  fontWeight: isUnread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: isUnread
                                      ? ChatTheme.metaText
                                      : ChatTheme.listSubtitle,
                                ),
                              )
                            : const Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ChatTheme.listSubtitle,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                            color: ChatTheme.unreadBadge,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            room.unreadCount > 99
                                ? '99+'
                                : '${room.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Text(
      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
      style: const TextStyle(
        color: ChatTheme.metaText,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    );
  }
}
