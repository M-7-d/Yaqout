// Live Stream domain entity
class LiveStreamEntity {
  final String id;
  final String sellerId;
  final String? productId;
  final String agoraChannel;
  final String title;
  final String status; // scheduled | live | ended
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int viewerCount;
  final int likesCount;
  final DateTime createdAt;

  // Joined
  final String? sellerName;
  final String? sellerAvatar;

  const LiveStreamEntity({
    required this.id,
    required this.sellerId,
    this.productId,
    required this.agoraChannel,
    required this.title,
    this.status = 'scheduled',
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.viewerCount = 0,
    this.likesCount = 0,
    required this.createdAt,
    this.sellerName,
    this.sellerAvatar,
  });

  bool get isLive      => status == 'live';
  bool get isScheduled => status == 'scheduled';
  bool get isEnded     => status == 'ended';
}
