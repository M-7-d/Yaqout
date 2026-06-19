import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/stream_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/live_stream_message_entity.dart';
import '../../../../features/products/presentation/providers/product_provider.dart';
import '../../../../features/products/presentation/providers/follow_provider.dart';

class LiveStreamScreen extends ConsumerStatefulWidget {
  final String streamId;
  const LiveStreamScreen({required this.streamId, super.key});

  @override
  ConsumerState<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends ConsumerState<LiveStreamScreen>
    with WidgetsBindingObserver {
  bool _isHost = false;
  bool _canPop = false;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _prevLikeCount = 0;
  bool _likeTrigger = false;
  RealtimeChannel? _presenceChannel;
  List<Map<String, dynamic>> _viewersList = [];

  // TikTok Live UI enhancements state
  final StreamController<({double x, double y})> _heartStreamController = StreamController<({double x, double y})>.broadcast();
  int _userCoins = 1500;
  List<_ActiveGiftCombo> _giftCombos = [];
  List<LiveStreamChatFeedItem> _localEvents = [];
  final Set<String> _trackedViewerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _join();
    _initPresence();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Manage stream state depending on the role (host vs viewer)
    if (_isHost) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        // Host minimized / switched app: set paused state in presence and mute Agora
        _updateHostPauseState(true);
      } else if (state == AppLifecycleState.resumed) {
        // Host returned to app: clear paused state in presence, restore Agora, and check status
        _updateHostPauseState(false);
        _checkIfStreamEnded();
      } else if (state == AppLifecycleState.detached) {
        // Host killed the app: gracefully end the live stream
        _leaveSync();
      }
    } else {
      // For viewers: they can background and return to the app.
      // But if the app is killed (detached), clean up their viewer count.
      if (state == AppLifecycleState.detached) {
        _leaveSync();
      }
    }
  }

  void _updateHostPauseState(bool paused) {
    if (!_isHost) return;
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    // 1. Update presence metadata so current/new viewers see the pause state
    _presenceChannel?.track({
      'user_id': user.id,
      'full_name': user.fullName ?? 'User',
      'avatar_url': user.avatarUrl,
      'is_paused': paused,
    });

    // 2. Mute local camera and microphone on Agora
    final agoraNotifier = ref.read(agoraProvider.notifier);
    if (paused) {
      agoraNotifier.engine?.muteLocalAudioStream(true);
      agoraNotifier.engine?.muteLocalVideoStream(true);
    } else {
      final agoraState = ref.read(agoraProvider);
      agoraNotifier.engine?.muteLocalAudioStream(agoraState.isMuted);
      agoraNotifier.engine?.muteLocalVideoStream(agoraState.isCameraOff);
    }
  }

  void _checkIfStreamEnded() async {
    try {
      final streamDetail = await ref.read(streamRepositoryProvider).getStreamById(widget.streamId);
      if (streamDetail.isEnded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The live stream was ended due to inactivity')),
        );
        _leave();
      }
    } catch (_) {}
  }

  /// Synchronous best-effort cleanup for when the app is being killed.
  /// Calls leave on the Agora notifier without awaiting since the engine
  /// may be destroyed mid-flight.
  void _leaveSync() {
    if (_canPop) return; // already left
    _canPop = true; // prevent duplicate calls from multiple lifecycle hooks
    try {
      ref.read(agoraProvider.notifier).leave(widget.streamId, isHost: _isHost);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Safety net: ensure the stream is ended if dispose is called
    // without going through _leave() (e.g. widget tree rebuild).
    _leaveSync();
    _presenceChannel?.unsubscribe();
    _msgController.dispose();
    _scrollController.dispose();
    _heartStreamController.close();
    super.dispose();
  }

  Future<void> _join() async {
    // Request permissions for camera and microphone
    final status = await [Permission.camera, Permission.microphone].request();
    
    final cameraStatus = status[Permission.camera];
    final micStatus = status[Permission.microphone];

    if (cameraStatus != PermissionStatus.granted ||
        micStatus != PermissionStatus.granted) {
      if (mounted) {
        if (cameraStatus == PermissionStatus.permanentlyDenied ||
            micStatus == PermissionStatus.permanentlyDenied) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Permissions Required', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Camera and Microphone permissions are permanently denied. Please enable them in app settings to use live streaming.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pop();
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(ctx);
                    context.pop();
                  },
                  child: const Text('Open Settings', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera and Microphone permissions are required')),
          );
          context.pop();
        }
      }
      return;
    }

    final streamDetail = await ref
        .read(streamRepositoryProvider)
        .getStreamById(widget.streamId);
    final user = ref.read(authNotifierProvider).valueOrNull;

    _isHost = user?.id == streamDetail.sellerId;

    if (_isHost) {
      await ref
          .read(agoraProvider.notifier)
          .joinAsHost(widget.streamId, streamDetail.agoraChannel);
    } else {
      await ref
          .read(agoraProvider.notifier)
          .joinAsViewer(widget.streamId, streamDetail.agoraChannel);
    }
  }

  Future<void> _leave() async {
    if (_canPop) return;

    // Immediately set _canPop to true to prevent concurrent/multiple calls to leave().
    if (mounted) {
      setState(() {
        _canPop = true;
      });
    } else {
      _canPop = true;
    }

    try {
      // Safely end the live stream by stopping heartbeat, leaving Agora channel,
      // and updating the live stream status on the database.
      await ref
          .read(agoraProvider.notifier)
          .leave(widget.streamId, isHost: _isHost);
    } catch (e) {
      debugPrint('Error ending live stream: $e');
    }

    if (mounted) {
      context.pop();
    }
  }

  void _initPresence() {
    final client = Supabase.instance.client;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    _presenceChannel = client.channel('live_stream_presence_${widget.streamId}');
    _presenceChannel!
        .onBroadcast(
          event: 'gift',
          callback: (payload) {
            if (mounted) {
              final senderId = payload['sender_id'] as String;
              final senderName = payload['sender_name'] as String? ?? 'User';
              final senderAvatar = payload['sender_avatar'] as String?;
              final giftId = payload['gift_id'] as String;
              final giftName = payload['gift_name'] as String;
              final giftIcon = payload['gift_icon'] as String;

              _onGiftReceived(
                userId: senderId,
                userName: senderName,
                userAvatar: senderAvatar,
                giftId: giftId,
                giftName: giftName,
                giftIcon: giftIcon,
              );
            }
          },
        )
        .onPresenceSync((_) {
          final state = _presenceChannel!.presenceState();
          final viewers = <Map<String, dynamic>>[];
          for (final presenceState in state) {
            for (final presence in presenceState.presences) {
              viewers.add(Map<String, dynamic>.from(presence.payload));
            }
          }

          // Detect new joins
          final currentUserId = user.id;
          for (final viewer in viewers) {
            final userId = viewer['user_id'] as String?;
            final fullName = viewer['full_name'] as String? ?? 'User';
            final avatarUrl = viewer['avatar_url'] as String?;
            if (userId != null && userId != currentUserId && !_trackedViewerIds.contains(userId)) {
              _trackedViewerIds.add(userId);
              _addLocalEventMessage(
                id: 'join_${userId}_${DateTime.now().millisecondsSinceEpoch}',
                senderId: userId,
                senderName: fullName,
                senderAvatar: avatarUrl,
                content: 'joined the room',
                type: LiveStreamChatFeedType.join,
              );
            }
          }

          if (mounted) {
            setState(() {
              _viewersList = viewers;
            });
          }
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _presenceChannel!.track({
              'user_id': user.id,
              'full_name': user.fullName ?? 'User',
              'avatar_url': user.avatarUrl,
            });
          }
        });
  }

  void _onGiftReceived({
    required String userId,
    required String userName,
    String? userAvatar,
    required String giftId,
    required String giftName,
    required String giftIcon,
  }) {
    // Add event in chat feed
    _addLocalEventMessage(
      id: 'gift_${userId}_${giftId}_${DateTime.now().millisecondsSinceEpoch}',
      senderId: userId,
      senderName: userName,
      senderAvatar: userAvatar,
      content: 'sent $giftName $giftIcon',
      type: LiveStreamChatFeedType.gift,
      giftName: giftName,
      giftIcon: giftIcon,
    );

    // Manage Left-Side combo overlay
    setState(() {
      final existingComboIndex = _giftCombos.indexWhere(
        (c) => c.userId == userId && c.giftId == giftId,
      );

      if (existingComboIndex != -1) {
        final existing = _giftCombos[existingComboIndex];
        existing.count += 1;
        existing.lastUpdated = DateTime.now();
      } else {
        final newCombo = _ActiveGiftCombo(
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          giftId: giftId,
          giftName: giftName,
          giftIcon: giftIcon,
          count: 1,
          lastUpdated: DateTime.now(),
        );
        _giftCombos.add(newCombo);
      }
    });

    // Cleanup stale combos after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _giftCombos.removeWhere((c) {
            final isStale = DateTime.now().difference(c.lastUpdated).inSeconds >= 4;
            return isStale && c.userId == userId && c.giftId == giftId;
          });
        });
      }
    });
  }

  void _addLocalEventMessage({
    required String id,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    required LiveStreamChatFeedType type,
    String? giftName,
    String? giftIcon,
  }) {
    if (mounted) {
      setState(() {
        _localEvents.add(LiveStreamChatFeedItem(
          id: id,
          senderId: senderId,
          senderName: senderName,
          senderAvatar: senderAvatar,
          content: content,
          createdAt: DateTime.now(),
          type: type,
          giftName: giftName,
          giftIcon: giftIcon,
        ));
      });
      _scrollToBottom();
    }
  }

  void _showViewersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Who is watching (${_viewersList.length})', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: _viewersList.isEmpty
                    ? const Center(child: Text('No viewers yet', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _viewersList.length,
                        itemBuilder: (ctx, i) {
                          final v = _viewersList[i];
                          final avatarUrl = v['avatar_url'] as String?;
                          final name = v['full_name'] as String? ?? 'User';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(name, style: const TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/sellers/${v['user_id']}');
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    _msgController.clear();
    try {
      await ref.read(streamRepositoryProvider).sendMessage(
            streamId: widget.streamId,
            senderId: user.id,
            content: text,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $e')),
        );
      }
    }
  }

  void _addLike() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    setState(() {
      _likeTrigger = !_likeTrigger;
    });

    // Spawn a local heart animation from bottom right area (near the like button)
    _heartStreamController.add((
      x: MediaQuery.of(context).size.width - 40,
      y: MediaQuery.of(context).size.height - 80,
    ));

    try {
      await ref.read(streamRepositoryProvider).addLike(
            streamId: widget.streamId,
            userId: user.id,
          );
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _sendGift(_GiftItem gift) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    if (_userCoins < gift.coins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient coins! Tap the balance to refill.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Deduct coins locally
    setState(() {
      _userCoins -= gift.coins;
    });

    // Broadcast the gift to everyone in the channel
    try {
      await _presenceChannel!.sendBroadcastMessage(
        event: 'gift',
        payload: {
          'sender_id': user.id,
          'sender_name': user.fullName ?? 'User',
          'sender_avatar': user.avatarUrl,
          'gift_id': gift.id,
          'gift_name': gift.name,
          'gift_icon': gift.icon,
        },
      );

      // Emit multiple local floating hearts from bottom-right on successful gift send
      for (int i = 0; i < 5; i++) {
        _heartStreamController.add((
          x: MediaQuery.of(context).size.width - 40 - (12.0 * i),
          y: MediaQuery.of(context).size.height - 80,
        ));
      }
    } catch (e) {
      // Fail silently
    }
  }
  void _shareStream() async {
    final url = 'https://example.com/stream/${widget.streamId}';
    await Share.share('Join my live stream on Yaqout! $url');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share dialog opened')),
      );
    }
  }

  void _showGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header: Balance & Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Send Gifts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Refill balance for testing!
                            setState(() {
                              _userCoins += 1500;
                            });
                            setSheetState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🪙 ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '$_userCoins Coins',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.add_circle_outline_rounded, size: 14, color: Colors.amber),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Grid of Gifts
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _kGifts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (ctx, idx) {
                        final gift = _kGifts[idx];
                        final canAfford = _userCoins >= gift.coins;

                        return GestureDetector(
                          onTap: () {
                            if (canAfford) {
                              _sendGift(gift);
                              setSheetState(() {});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Insufficient coins! Tap the balance to refill.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  gift.icon,
                                  style: const TextStyle(fontSize: 32),
                                ).animate().scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.0, 1.0),
                                  duration: 200.ms,
                                  curve: Curves.easeOutBack,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  gift.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '🪙',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${gift.coins}',
                                      style: TextStyle(
                                        color: canAfford ? Colors.amber : Colors.white24,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showModerationOptions(String senderId, String senderName) {
    if (!_isHost) return;
    final currentUser = ref.read(authNotifierProvider).valueOrNull;
    if (currentUser == null || senderId == currentUser.id) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Manage $senderName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: AppColors.error),
                title: const Text('Block User', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref.read(streamRepositoryProvider).blockUser(
                          streamId: widget.streamId,
                          blockedUserId: senderId,
                          blockedById: currentUser.id,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$senderName has been blocked')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to block: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded, color: Colors.white70),
                title: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<LiveStreamChatFeedItem> _getCombinedFeed(List<LiveStreamMessageEntity> dbMessages) {
    final list = <LiveStreamChatFeedItem>[];

    // Map DB messages
    for (final msg in dbMessages) {
      list.add(LiveStreamChatFeedItem(
        id: msg.id,
        senderId: msg.senderId,
        senderName: msg.senderName,
        senderAvatar: msg.senderAvatar,
        content: msg.content,
        createdAt: msg.createdAt,
        type: LiveStreamChatFeedType.message,
      ));
    }

    // Add local event feed items
    list.addAll(_localEvents);

    // Sort chronologically
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final agora = ref.watch(agoraProvider);
    final engine = ref.read(agoraProvider.notifier).engine;
    final user = ref.watch(authNotifierProvider).valueOrNull;

    // Realtime stream detail
    final streamDetailAsync = ref.watch(singleLiveStreamProvider(widget.streamId));
    // Realtime chat messages
    final messagesAsync = ref.watch(liveStreamMessagesProvider(widget.streamId));

    // Live block listener for viewers
    if (user != null && !_isHost) {
      ref.listen<AsyncValue<bool>>(
        userBlockStreamProvider((streamId: widget.streamId, userId: user.id)),
        (prev, next) {
          if (next.value == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You have been blocked from this live stream')),
            );
            _leave();
          }
        },
      );
    }

    // Live ended listener for viewers
    if (user != null && !_isHost) {
      ref.listen<AsyncValue<LiveStreamEntity>>(
        singleLiveStreamProvider(widget.streamId),
        (prev, next) {
          if (next.value?.isEnded == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('The live stream has ended')),
            );
            _leave();
          }
        },
      );
    }

    return PopScope(
      canPop: _canPop,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _leave();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: streamDetailAsync.when(
        data: (streamDetail) {
          final sellerAsync = ref.watch(userByIdProvider(streamDetail.sellerId));
          final followedSellers = ref.watch(followedSellersProvider);
          final isFollowing = followedSellers.contains(streamDetail.sellerId);

          final isHostActive = _viewersList.any((v) => v['user_id'] == streamDetail.sellerId);
          final hostPresence = _viewersList.firstWhere(
            (v) => v['user_id'] == streamDetail.sellerId,
            orElse: () => {},
          );
          final isHostPaused = hostPresence['is_paused'] == true;
          final showPauseOverlay = !_isHost && (!isHostActive || isHostPaused);

          // Trigger brief hearts state when likes count changes remotely
          if (streamDetail.likesCount > _prevLikeCount) {
            final difference = streamDetail.likesCount - _prevLikeCount;
            _prevLikeCount = streamDetail.likesCount;
            // Spawn some floating hearts automatically from bottom right to represent others liking
            for (int i = 0; i < math.min(difference, 5); i++) {
              _heartStreamController.add((
                x: MediaQuery.of(context).size.width - 40 - (12.0 * i),
                y: MediaQuery.of(context).size.height - 80,
              ));
            }
            _likeTrigger = !_likeTrigger;
          }

          return Stack(
            children: [
              // ── 1. Video Surface ──────────────────────────────────────────
              if (agora.isJoined && engine != null)
                Positioned.fill(
                  child: _isHost
                      ? (agora.isCameraOff
                          ? Container(
                              color: Colors.black,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam_off_rounded, size: 64, color: Colors.white54),
                                    SizedBox(height: 16),
                                    Text('Camera is off', style: TextStyle(color: Colors.white54, fontSize: 16)),
                                  ],
                                ),
                              ),
                            )
                          : AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: engine,
                                canvas: const VideoCanvas(uid: 0),
                                useFlutterTexture: true,
                              ),
                            ))
                      : agora.remoteUids.isNotEmpty
                          ? AgoraVideoView(
                              controller: VideoViewController.remote(
                                rtcEngine: engine,
                                canvas: VideoCanvas(uid: agora.remoteUids.first),
                                connection: RtcConnection(
                                  channelId: streamDetail.agoraChannel,
                                ),
                                useFlutterTexture: true,
                              ),
                            )
                          : const Center(
                              child: Text(
                                'Waiting for host...',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                )
              else if (agora.error != null)
                Center(
                  child: Text(
                    agora.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 15),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Beautiful "Live is Paused" overlay
              if (showPauseOverlay)
                Positioned.fill(
                  child: Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: const Icon(
                              Icons.pause_rounded,
                              size: 48,
                              color: Colors.amber,
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1000.ms, curve: Curves.easeInOut),
                          const SizedBox(height: 24),
                          Text(
                            'Live Stream Paused',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'The host is temporarily away. Stay tuned!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Gesture Detector for Screen Likes (tap on the video area only)
              // Limited to the top portion so it does NOT block the chat input.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).size.height * 0.45,
                child: GestureDetector(
                  onTapDown: (details) {
                    _heartStreamController.add((
                      x: details.globalPosition.dx,
                      y: details.globalPosition.dy,
                    ));
                    _addLike();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // High-Performance Floating Hearts Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: _FloatingHeartsOverlay(
                    likeStream: _heartStreamController.stream,
                  ),
                ),
              ),

              // Left-Side Gift Combo Notifications Stack
              Positioned(
                left: 16,
                bottom: MediaQuery.of(context).size.height * 0.42,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: _giftCombos.map((combo) {
                      return _GiftComboPill(
                        key: ValueKey('${combo.userId}_${combo.giftId}'),
                        combo: combo,
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── 2. Top Header HUD Overlay ───────────────────────────────
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        // Seller Avatar and Name HUD
                        GestureDetector(
                          onTap: () {
                            context.push('/sellers/${streamDetail.sellerId}');
                          },
                          child: _GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                sellerAsync.when(
                                  data: (seller) => CircleAvatar(
                                    radius: 16,
                                    backgroundImage: seller?.avatarUrl != null && seller!.avatarUrl!.isNotEmpty
                                        ? NetworkImage(seller.avatarUrl!)
                                        : null,
                                    child: seller?.avatarUrl == null
                                        ? const Icon(Icons.person, size: 16)
                                        : null,
                                  ),
                                  loading: () => const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                  ),
                                  error: (_, __) => const CircleAvatar(
                                    radius: 16,
                                    child: Icon(Icons.person, size: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      sellerAsync.valueOrNull?.fullName ?? streamDetail.sellerName ?? 'Seller',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6, height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (user?.id != streamDetail.sellerId) ...[
                                  const SizedBox(width: 8),
                                  // Follow / Following toggle button
                                  GestureDetector(
                                    onTap: () async {
                                      final wasFollowing = isFollowing;
                                      try {
                                        await ref.read(followedSellersProvider.notifier).toggleFollow(streamDetail.sellerId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(wasFollowing 
                                                ? 'Unfollowed seller successfully' 
                                                : 'You are now following this seller'
                                              ),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed: $e'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isFollowing ? Colors.white24 : Colors.redAccent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Viewer count badge & Avatars
                        GestureDetector(
                          onTap: _showViewersBottomSheet,
                          child: _GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                if (_viewersList.isNotEmpty) ...[
                                  SizedBox(
                                    width: (_viewersList.length > 3 ? 3 : _viewersList.length) * 12.0 + 4,
                                    height: 18,
                                    child: Stack(
                                      children: List.generate(_viewersList.length > 3 ? 3 : _viewersList.length, (index) {
                                        final v = _viewersList[index];
                                        final avatarUrl = v['avatar_url'] as String?;
                                        return Positioned(
                                          left: index * 12.0,
                                          child: CircleAvatar(
                                            radius: 9,
                                            backgroundColor: Colors.black,
                                            child: CircleAvatar(
                                              radius: 8,
                                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                              child: avatarUrl == null ? const Icon(Icons.person, size: 8) : null,
                                            ),
                                          ),
                                        );
                                      }).reversed.toList(),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                const Icon(Icons.remove_red_eye_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 5),
                                Text(
                                  '${_viewersList.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Likes Count HUD
                        _GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded, size: 14, color: Colors.pinkAccent),
                              const SizedBox(width: 5),
                              Text(
                                '${streamDetail.likesCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Share Button
                        GestureDetector(
                          onTap: _shareStream,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: const Icon(Icons.share, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 3. Interactive UI Overlay (Messages and Inputs) ─────────
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Showcase Product Card (if linked)
                        if (streamDetail.productId != null && streamDetail.productId!.isNotEmpty) ...[
                          _ProductShowcaseCard(productId: streamDetail.productId!)
                              .animate()
                              .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOutBack)
                              .fadeIn(duration: 200.ms),
                          const SizedBox(height: 12),
                        ],

                        // A. Realtime Chat Window
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.32,
                          ),
                          child: messagesAsync.when(
                            data: (list) {
                              final combined = _getCombinedFeed(list);
                              _scrollToBottom();
                              if (combined.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Welcome to the live chat! Be friendly.',
                                    style: TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                );
                              }
                              return ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.white, Colors.white],
                                    stops: [0.0, 0.15, 1.0],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.dstIn,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: combined.length,
                                  itemBuilder: (ctx, i) {
                                    final msg = combined[i];
                                    return _ChatMessageItem(
                                      message: msg,
                                      hostId: streamDetail.sellerId,
                                      onTap: () {
                                        if (_isHost) {
                                          _showModerationOptions(
                                            msg.senderId,
                                            msg.senderName ?? 'User',
                                          );
                                        }
                                      },
                                    ).animate().fadeIn(duration: 150.ms).slideY(begin: 0.1, end: 0);
                                  },
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (e, _) => Text(
                              'Chat failed to load: $e',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // B. Interaction Row (Message input & Hearts)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 14),
                                    const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _msgController,
                                        textCapitalization: TextCapitalization.sentences,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Write a message...',
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _sendMessage,
                                      icon: const Icon(
                                        Icons.send_rounded,
                                        color: Colors.amberAccent,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Pulsing Heart (Like) button for viewers
                            if (!_isHost)
                              GestureDetector(
                                onTap: _addLike,
                                child: Container(
                                  width: 44, height: 44,
                                  decoration: const BoxDecoration(
                                    color: Colors.pink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                                )
                                    .animate(target: _likeTrigger ? 1 : 0)
                                    .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 100.ms, curve: Curves.bounceOut)
                                    .then()
                                    .scale(begin: const Offset(1.3, 1.3), end: const Offset(1, 1), duration: 100.ms),
                              ),

                            // Mute/Video Controls for Host
                            if (_isHost) ...[
                              GestureDetector(
                                onTap: () => ref.read(agoraProvider.notifier).toggleMute(),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: agora.isMuted ? AppColors.error : Colors.white12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    agora.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                    color: Colors.white, size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => ref.read(agoraProvider.notifier).toggleCamera(),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: agora.isCameraOff ? AppColors.error : Colors.white12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    agora.isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                                    color: Colors.white, size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => ref.read(agoraProvider.notifier).toggleSwitchCamera(),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.cameraswitch_rounded,
                                    color: Colors.white, size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _leave,
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white, size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 14),
                Text('Error joining live: $e', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

// ── Models & Types for Enhanced Live Room ────────────────────────────────────

enum LiveStreamChatFeedType {
  message,
  join,
  gift,
}

class LiveStreamChatFeedItem {
  final String id;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final DateTime createdAt;
  final LiveStreamChatFeedType type;
  final String? giftName;
  final String? giftIcon;

  const LiveStreamChatFeedItem({
    required this.id,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    required this.createdAt,
    required this.type,
    this.giftName,
    this.giftIcon,
  });
}

class _ActiveGiftCombo {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String giftId;
  final String giftName;
  final String giftIcon;
  int count;
  DateTime lastUpdated;

  _ActiveGiftCombo({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.giftId,
    required this.giftName,
    required this.giftIcon,
    required this.count,
    required this.lastUpdated,
  });
}

class _GiftItem {
  final String id;
  final String name;
  final String icon;
  final int coins;
  final Color color;

  const _GiftItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.coins,
    required this.color,
  });
}

const List<_GiftItem> _kGifts = [
  _GiftItem(id: 'rose', name: 'Rose', icon: '🌹', coins: 1, color: Colors.redAccent),
  _GiftItem(id: 'icecream', name: 'Ice Cream', icon: '🍦', coins: 5, color: Colors.orangeAccent),
  _GiftItem(id: 'heart', name: 'Heart', icon: '💖', coins: 10, color: Colors.pinkAccent),
  _GiftItem(id: 'ruby', name: 'Ruby', icon: '💎', coins: 29, color: Colors.blueAccent),
  _GiftItem(id: 'glow_ring', name: 'Glow Ring', icon: '💍', coins: 99, color: Colors.cyanAccent),
  _GiftItem(id: 'crown', name: 'Crown', icon: '👑', coins: 299, color: Colors.amberAccent),
  _GiftItem(id: 'yacht', name: 'Yacht', icon: '🛥️', coins: 999, color: Colors.tealAccent),
  _GiftItem(id: 'galaxy', name: 'Galaxy', icon: '🌌', coins: 1999, color: Colors.purpleAccent),
];

// ── Custom Chat Message Widget ───────────────────────────────────────────────

class _ChatMessageItem extends ConsumerWidget {
  final LiveStreamChatFeedItem message;
  final String hostId;
  final VoidCallback onTap;

  const _ChatMessageItem({
    required this.message,
    required this.hostId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final senderAsync = ref.watch(userByIdProvider(message.senderId));
    final isHost = message.senderId == hostId;
    final nameColor = _getUserColor(message.senderId);

    if (message.type == LiveStreamChatFeedType.join) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.cyanAccent, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: message.senderName ?? 'User',
                      style: TextStyle(
                        color: nameColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const TextSpan(
                      text: ' joined the live room',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (message.type == LiveStreamChatFeedType.gift) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: message.senderName ?? 'User',
                      style: TextStyle(
                        color: nameColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ' sent ${message.giftName} ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: message.giftIcon ?? '🎁',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender Avatar
            senderAsync.when(
              data: (user) => CircleAvatar(
                radius: 14,
                backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? const Icon(Icons.person, size: 14, color: Colors.white70)
                    : null,
              ),
              loading: () => const CircleAvatar(
                radius: 14,
                child: Icon(Icons.person, size: 14, color: Colors.white70),
              ),
              error: (_, __) => const CircleAvatar(
                radius: 14,
                child: Icon(Icons.person, size: 14, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        senderAsync.valueOrNull?.fullName ?? message.senderName ?? 'User',
                        style: TextStyle(
                          color: nameColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (isHost) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Host',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.pink.withOpacity(0.4)),
                          ),
                          child: const Text(
                            'Lv.3',
                            style: TextStyle(
                              color: Colors.pinkAccent,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUserColor(String userId) {
    final hash = userId.hashCode;
    final colors = [
      Colors.amberAccent,
      Colors.lightBlueAccent,
      Colors.lightGreenAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
    ];
    return colors[hash.abs() % colors.length];
  }
}

// ── Left Side Gift Combo Pill Widget ──────────────────────────────────────────

class _GiftComboPill extends StatefulWidget {
  final _ActiveGiftCombo combo;
  const _GiftComboPill({required this.combo, super.key});

  @override
  State<_GiftComboPill> createState() => _GiftComboPillState();
}

class _GiftComboPillState extends State<_GiftComboPill> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.pink.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.combo.userAvatar != null && widget.combo.userAvatar!.isNotEmpty
                          ? NetworkImage(widget.combo.userAvatar!)
                          : null,
                      child: widget.combo.userAvatar == null
                          ? const Icon(Icons.person, size: 18, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.combo.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sent ${widget.combo.giftName}',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.combo.giftIcon,
                      style: const TextStyle(fontSize: 28),
                    )
                    .animate(key: ValueKey(widget.combo.count))
                    .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.4, 1.4), duration: 200.ms, curve: Curves.bounceOut)
                    .then()
                    .scale(begin: const Offset(1.4, 1.4), end: const Offset(1.0, 1.0), duration: 100.ms),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bouncing Combo Multiplier
          Text(
            'x${widget.combo.count}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Colors.yellow, Colors.orange, Colors.red],
                ).createShader(const Rect.fromLTWH(0, 0, 80, 40)),
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
                Shadow(
                  color: Colors.amber.withOpacity(0.5),
                  offset: const Offset(0, 0),
                  blurRadius: 8,
                ),
              ],
            ),
          )
          .animate(key: ValueKey(widget.combo.count))
          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.7, 1.7), duration: 180.ms, curve: Curves.elasticOut)
          .then()
          .scale(begin: const Offset(1.7, 1.7), end: const Offset(1.0, 1.0), duration: 100.ms),
        ],
      ),
    )
    .animate()
    .slideX(begin: -1.0, end: 0.0, duration: 300.ms, curve: Curves.easeOutCubic)
    .fadeIn(duration: 250.ms);
  }
}

// ── High-Performance Floating Hearts Overlay Widget ──────────────────────────

class _FloatingHeartsOverlay extends StatefulWidget {
  final Stream<({double x, double y})> likeStream;
  const _FloatingHeartsOverlay({required this.likeStream});

  @override
  State<_FloatingHeartsOverlay> createState() => _FloatingHeartsOverlayState();
}

class _FloatingHeartsOverlayState extends State<_FloatingHeartsOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_HeartData> _hearts = [];
  final math.Random _random = math.Random();

  final List<IconData> _icons = [
    Icons.favorite_rounded,
    Icons.favorite_border_rounded,
    Icons.star_rounded,
    Icons.thumb_up_rounded,
    Icons.bolt_rounded,
  ];

  final List<Color> _colors = [
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.amberAccent,
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    widget.likeStream.listen((coord) {
      if (mounted) {
        setState(() {
          _hearts.add(_HeartData(
            id: DateTime.now().millisecondsSinceEpoch / 1000.0,
            startX: coord.x,
            startY: coord.y,
            color: _colors[_random.nextInt(_colors.length)],
            scale: 0.6 + _random.nextDouble() * 0.8,
            swaySpeed: 1.2 + _random.nextDouble() * 1.8,
            swayWidth: 15.0 + _random.nextDouble() * 25.0,
            icon: _icons[_random.nextInt(_icons.length)],
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _hearts.removeWhere((h) => now - h.id > 2.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _HeartsPainter(
            hearts: _hearts,
            animationValue: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _HeartData {
  final double id;
  final double startX;
  final double startY;
  final Color color;
  final double scale;
  final double swaySpeed;
  final double swayWidth;
  final IconData icon;

  _HeartData({
    required this.id,
    required this.startX,
    required this.startY,
    required this.color,
    required this.scale,
    required this.swaySpeed,
    required this.swayWidth,
    required this.icon,
  });
}

class _HeartsPainter extends CustomPainter {
  final List<_HeartData> hearts;
  final double animationValue;

  _HeartsPainter({required this.hearts, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;

    for (final heart in hearts) {
      final age = now - heart.id;
      final progress = age / 2.0; // 2 seconds lifetime
      if (progress >= 1.0 || progress < 0.0) continue;

      final y = heart.startY - (progress * 350.0);
      final x = heart.startX + math.sin(progress * heart.swaySpeed * math.pi) * heart.swayWidth;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final scale = heart.scale * (progress < 0.15 ? (progress / 0.15) : 1.0);

      textPainter.text = TextSpan(
        text: String.fromCharCode(heart.icon.codePoint),
        style: TextStyle(
          fontSize: 26 * scale,
          fontFamily: heart.icon.fontFamily,
          package: heart.icon.fontPackage,
          color: heart.color.withOpacity(opacity),
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.35),
              offset: const Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter oldDelegate) => true;
}

// ── Product Showcase Card Widget ─────────────────────────────────────────────

class _ProductShowcaseCard extends ConsumerWidget {
  final String productId;
  const _ProductShowcaseCard({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return productAsync.when(
      data: (product) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.white12,
                      child: product.primaryImage.isNotEmpty
                          ? Image.network(product.primaryImage, fit: BoxFit.cover)
                          : const Icon(Icons.shopping_bag_rounded, color: Colors.white70, size: 24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      context.push('/product/${product.id}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.pink, Colors.redAccent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Buy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        width: 220,
        height: 66,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
        ),
      ),
      error: (_, __) => const SizedBox(),
    );
  }
}

// ── Glass Container Helper Widget ─────────────────────────────────────────────

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  const _GlassContainer({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}
