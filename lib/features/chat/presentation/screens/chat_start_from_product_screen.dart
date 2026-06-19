import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/chat_provider.dart';

/// Opens or reuses a chat room for buyer + seller + optional product, then
/// replaces this route with [ChatRoomScreen].
class ChatStartFromProductScreen extends ConsumerStatefulWidget {
  final String sellerId;
  final String buyerId;
  final String? productId;

  const ChatStartFromProductScreen({
    required this.sellerId,
    required this.buyerId,
    this.productId,
    super.key,
  });

  @override
  ConsumerState<ChatStartFromProductScreen> createState() =>
      _ChatStartFromProductScreenState();
}

class _ChatStartFromProductScreenState
    extends ConsumerState<ChatStartFromProductScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRoom());
  }

  Future<void> _openRoom() async {
    if (widget.sellerId.isEmpty || widget.buyerId.isEmpty) {
      setState(() => _error = 'Missing seller or buyer.');
      return;
    }
    if (widget.sellerId == widget.buyerId) {
      setState(() => _error = 'You cannot start a chat with yourself.');
      return;
    }

    try {
      final repo = ref.read(chatRepositoryProvider);
      final room = await repo.getOrCreateRoom(
        buyerId: widget.buyerId,
        sellerId: widget.sellerId,
        productId: widget.productId,
      );
      ref.invalidate(userRoomsProvider(widget.buyerId));
      ref.invalidate(userRoomsProvider(widget.sellerId));
      if (!mounted) return;
      context.pushReplacement('/chat/${room.id}');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Messages'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go back'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      'Opening conversation…',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.productId != null
                          ? 'The seller will see which product this is about.'
                          : 'Connecting you with the seller.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecond,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
