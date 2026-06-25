import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/chat_entities.dart';
import '../providers/chat_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/settings/presentation/providers/blocked_users_provider.dart';
import '../../../../features/settings/presentation/providers/muted_users_provider.dart';
import '../theme/chat_theme.dart';
import '../widgets/chat_wallpaper.dart';
import '../widgets/whatsapp_message_bubble.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const ChatRoomScreen({required this.roomId, super.key});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final hasText = _ctrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(authNotifierProvider).valueOrNull;
      if (user != null) {
        await ref
            .read(chatRepositoryProvider)
            .markRoomAsRead(widget.roomId, user.id);
        ref.invalidate(userRoomsProvider(user.id));
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_isSending) return;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final savedText = text;
    _ctrl.clear();
    setState(() => _isSending = true);
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            roomId: widget.roomId,
            senderId: user.id,
            content: savedText,
          );
      _scrollToBottom();
    } catch (e) {
      _ctrl.text = savedText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ChatTheme.listBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: ChatTheme.accentDark),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: ChatTheme.accentDark),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked =
          await ImagePicker().pickImage(source: source, imageQuality: 70);
      if (picked == null) return;

      setState(() => _isSending = true);
      await ref.read(chatRepositoryProvider).sendMessage(
            roomId: widget.roomId,
            senderId: user.id,
            media: File(picked.path),
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  List<_ChatListEntry> _buildEntries(List<MessageEntity> messages) {
    final entries = <_ChatListEntry>[];
    for (var i = 0; i < messages.length; i++) {
      entries.add(_ChatListEntry.message(messages[i]));
      if (i < messages.length - 1) {
        if (!_isSameDay(messages[i].createdAt, messages[i + 1].createdAt)) {
          entries.add(_ChatListEntry.date(messages[i + 1].createdAt));
        }
      } else {
        entries.add(_ChatListEntry.date(messages[i].createdAt));
      }
    }
    return entries;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.roomId));
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final roomAsync = ref.watch(chatRoomProvider(widget.roomId));

    final room = roomAsync.valueOrNull;
    final otherName = room?.otherUserName ?? 'Chat';
    final otherAvatar = room?.otherUserAvatar;
    final otherId = (room != null && user != null)
        ? (room.buyerId == user.id ? room.sellerId : room.buyerId)
        : null;

    messages.whenData((_) => _scrollToBottom());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: ChatTheme.headerBg,
      ),
      child: Scaffold(
        backgroundColor: ChatTheme.wallpaper,
        appBar: AppBar(
          backgroundColor: ChatTheme.headerBg,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          titleSpacing: 0,
          title: room == null
              ? const Text('Chat', style: TextStyle(color: Colors.white))
              : GestureDetector(
                  onTap: () {
                    if (otherId != null) context.push('/sellers/$otherId');
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: ChatTheme.headerLight,
                        backgroundImage: (otherAvatar != null &&
                                otherAvatar.isNotEmpty)
                            ? CachedNetworkImageProvider(
                                otherAvatar,
                                maxWidth: 72,
                                maxHeight: 72,
                              )
                            : null,
                        child: (otherAvatar == null || otherAvatar.isEmpty)
                            ? Text(
                                otherName.isNotEmpty
                                    ? otherName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          otherName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: ChatTheme.listBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 48),
              onSelected: (value) => _onMenuSelected(value, otherName, otherId,
                  otherAvatar, context, ref),
              itemBuilder: (context) {
                final isMuted = otherId != null && ref.watch(mutedUsersProvider.notifier).isMuted(otherId);
                return [
                  const PopupMenuItem(
                    value: 'view_profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: ChatTheme.metaText,
                            size: 20),
                        SizedBox(width: 12),
                        Text('View profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: isMuted ? 'unmute' : 'mute',
                    child: Row(
                      children: [
                        Icon(
                          isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                          color: ChatTheme.metaText, size: 20
                        ),
                        const SizedBox(width: 12),
                        Text(isMuted ? 'Unmute' : 'Mute'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: AppColors.error, size: 20),
                      SizedBox(width: 12),
                      Text('Block', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: AppColors.error,
                          size: 20),
                      SizedBox(width: 12),
                      Text('Report',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ];  
            },  
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ChatWallpaper(
                child: messages.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: ChatTheme.accent),
                  ),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (list) {
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'Messages and calls are end-to-end encrypted.\nSay hello! 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: ChatTheme.metaText,
                            height: 1.5,
                          ),
                        ),
                      );
                    }

                    final entries = _buildEntries(list);
                    return ListView.builder(
                      reverse: true,
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: entries.length,
                      itemBuilder: (ctx, i) {
                        final entry = entries[i];
                        if (entry.isDate) {
                          return ChatDateSeparator(date: entry.date!);
                        }
                        final msg = entry.message!;
                        return WhatsAppMessageBubble(
                          message: msg,
                          isMe: msg.senderId == user?.id,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            _WhatsAppInputBar(
              controller: _ctrl,
              isSending: _isSending,
              hasText: _hasText,
              onSend: _send,
              onAttach: _pickAndSendImage,
            ),
          ],
        ),
      ),
    );
  }

  void _onMenuSelected(
    String value,
    String otherName,
    String? otherId,
    String? otherAvatar,
    BuildContext context,
    WidgetRef ref,
  ) {
    switch (value) {
      case 'view_profile':
        if (otherId != null) context.push('/sellers/$otherId');
        break;
      case 'mute':
        if (otherId != null) {
          ref.read(mutedUsersProvider.notifier).muteUser(otherId, otherName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$otherName has been muted')),
          );
        }
        break;
      case 'unmute':
        if (otherId != null) {
          ref.read(mutedUsersProvider.notifier).unmuteUser(otherId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$otherName has been unmuted')),
          );
        }
        break;
      case 'block':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Block user'),
            content: Text(
                'Are you sure you want to block $otherName? They won\'t be able to message you anymore.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (otherId != null) {
                    ref
                        .read(blockedUsersProvider.notifier)
                        .blockUser(otherId, otherName, otherAvatar);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$otherName has been blocked')),
                  );
                },
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Block'),
              ),
            ],
          ),
        );
        break;
      case 'report':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Report user'),
            content: Text(
                'Are you sure you want to report $otherName? We will review this conversation.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Report submitted. We\'ll review it shortly.')),
                  );
                },
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Report'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

class _ChatListEntry {
  final MessageEntity? message;
  final DateTime? date;

  const _ChatListEntry._({this.message, this.date});

  factory _ChatListEntry.message(MessageEntity m) =>
      _ChatListEntry._(message: m);

  factory _ChatListEntry.date(DateTime d) => _ChatListEntry._(date: d);

  bool get isDate => date != null;
}

class _WhatsAppInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _WhatsAppInputBar({
    required this.controller,
    required this.isSending,
    required this.hasText,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(6, 6, 6, bottom + 6),
      color: ChatTheme.inputBar,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ChatTheme.inputField,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: ChatTheme.metaText, size: 24),
                    onPressed: () {},
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(
                        minWidth: 40, minHeight: 40),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(
                        fontSize: 16,
                        color: ChatTheme.bubbleText,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: ChatTheme.listSubtitle),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: ChatTheme.metaText, size: 22),
                    onPressed: isSending ? null : onAttach,
                    constraints: const BoxConstraints(
                        minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: hasText ? ChatTheme.accent : ChatTheme.listSubtitle,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isSending ? null : (hasText ? onSend : null),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
