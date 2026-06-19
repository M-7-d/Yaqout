import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/chat_entities.dart';
import '../theme/chat_theme.dart';

class WhatsAppMessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;

  const WhatsAppMessageBubble({
    required this.message,
    required this.isMe,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: EdgeInsets.only(
          left: isMe ? 48 : 8,
          right: isMe ? 8 : 48,
          bottom: 2,
          top: 1,
        ),
        padding: message.hasMedia
            ? const EdgeInsets.all(3)
            : const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: BoxDecoration(
          color: isMe ? ChatTheme.sentBubble : ChatTheme.receivedBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isMe ? 8 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: message.hasMedia
            ? _MediaContent(message: message, time: time, isMe: isMe)
            : _TextContent(
                text: message.content ?? '',
                time: time,
                isMe: isMe,
                isRead: message.isRead,
              ),
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool isRead;

  const _TextContent({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 56, bottom: 2),
          child: Text(
            text,
            style: const TextStyle(
              color: ChatTheme.bubbleText,
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _TimeRow(time: time, isMe: isMe, isRead: isRead),
        ),
      ],
    );
  }
}

class _MediaContent extends StatelessWidget {
  final MessageEntity message;
  final String time;
  final bool isMe;

  const _MediaContent({
    required this.message,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: message.mediaUrl!,
            fit: BoxFit.cover,
            width: 240,
            placeholder: (_, __) => Container(
              width: 240,
              height: 180,
              color: ChatTheme.divider,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 240,
              height: 120,
              color: ChatTheme.divider,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _TimeRow(
                time: time,
                isMe: isMe,
                isRead: message.isRead,
                onDark: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String time;
  final bool isMe;
  final bool isRead;
  final bool onDark;

  const _TimeRow({
    required this.time,
    required this.isMe,
    required this.isRead,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDark
        ? Colors.white.withValues(alpha: 0.9)
        : ChatTheme.metaText.withValues(alpha: 0.85);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(fontSize: 11, color: color, height: 1),
        ),
        if (isMe) ...[
          const SizedBox(width: 3),
          Icon(
            isRead ? Icons.done_all : Icons.done,
            size: 14,
            color: isRead
                ? (onDark ? Colors.white : AppColors.primary)
                : color,
          ),
        ],
      ],
    );
  }
}

/// Centered date pill shown between message groups.
class ChatDateSeparator extends StatelessWidget {
  final DateTime date;

  const ChatDateSeparator({required this.date, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          _formatDate(date),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ChatTheme.datePillText,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(local);
    return DateFormat('d MMMM yyyy').format(local);
  }
}
