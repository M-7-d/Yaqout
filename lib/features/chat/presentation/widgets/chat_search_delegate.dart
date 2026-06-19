import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/chat_provider.dart';
import '../theme/chat_theme.dart';

class ChatSearchDelegate extends SearchDelegate {
  final String userId;
  ChatSearchDelegate(this.userId);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: ChatTheme.headerBg,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildChatList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildChatList(context);
  }

  Widget _buildChatList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final roomsAsync = ref.watch(userRoomsProvider(userId));
        
        return roomsAsync.when(
          data: (rooms) {
            final filtered = rooms.where((room) {
              final other = userId == room.buyerId
                  ? room.sellerName ?? 'Seller'
                  : room.buyerName ?? 'Buyer';
              return other.toLowerCase().contains(query.toLowerCase().trim());
            }).toList();

            if (filtered.isEmpty && query.isNotEmpty) {
              return Center(
                child: Text('No conversations found for "$query"',
                    style: const TextStyle(color: ChatTheme.metaText)),
              );
            }

            return ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 72,
                    color: ChatTheme.divider,
                  ),
              itemBuilder: (ctx, i) {
                final room = filtered[i];
                final other = userId == room.buyerId
                    ? room.sellerName ?? 'Seller'
                    : room.buyerName ?? 'Buyer';

                final otherName = room.otherUserName ?? other;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: ChatTheme.divider,
                    child: (room.otherUserAvatar != null && room.otherUserAvatar!.isNotEmpty)
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: room.otherUserAvatar!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                              errorWidget: (_, __, ___) => Text(
                                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: ChatTheme.metaText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18),
                              ),
                            ),
                          )
                        : Text(
                            otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: ChatTheme.metaText,
                                fontWeight: FontWeight.w600,
                                fontSize: 18),
                          ),
                  ),
                  title: Text(otherName),
                  subtitle: room.lastMessage != null
                      ? Text(room.lastMessage!, maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                  onTap: () {
                    close(context, null);
                    context.push('/chat/${room.id}');
                  },
                );
              },
            );
          },
          loading: () => const Center(
                child: CircularProgressIndicator(color: ChatTheme.accent),
              ),
          error: (e, _) => Center(child: Text(e.toString())),
        );
      },
    );
  }
}
