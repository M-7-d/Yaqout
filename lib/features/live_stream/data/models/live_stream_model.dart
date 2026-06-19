import '../../domain/entities/live_stream_entity.dart';

class LiveStreamModel extends LiveStreamEntity {
  const LiveStreamModel({
    required super.id,
    required super.sellerId,
    super.productId,
    required super.agoraChannel,
    required super.title,
    super.status,
    super.scheduledAt,
    super.startedAt,
    super.endedAt,
    super.viewerCount,
    super.likesCount,
    required super.createdAt,
    super.sellerName,
    super.sellerAvatar,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> j) {
    final profile = j['profiles'] as Map<String, dynamic>?;
    return LiveStreamModel(
      id:            j['id'] as String,
      sellerId:      j['seller_id'] as String,
      productId:     j['product_id'] as String?,
      agoraChannel:  j['agora_channel'] as String,
      title:         j['title'] as String? ?? '',
      status:        j['status'] as String? ?? 'scheduled',
      scheduledAt:   j['scheduled_at'] != null
          ? DateTime.tryParse(j['scheduled_at'] as String)
          : null,
      startedAt:     j['started_at'] != null
          ? DateTime.tryParse(j['started_at'] as String)
          : null,
      endedAt:       j['ended_at'] != null
          ? DateTime.tryParse(j['ended_at'] as String)
          : null,
      viewerCount:   (j['viewer_count'] as num?)?.toInt() ?? 0,
      likesCount:    (j['likes_count'] as num?)?.toInt() ?? 0,
      createdAt:     DateTime.parse(j['created_at'] as String),
      sellerName:    profile?['full_name'] as String?,
      sellerAvatar:  profile?['avatar_url'] as String?,
    );
  }

  LiveStreamEntity toEntity() => LiveStreamEntity(
        id:           id,
        sellerId:     sellerId,
        productId:    productId,
        agoraChannel: agoraChannel,
        title:        title,
        status:       status,
        scheduledAt:  scheduledAt,
        startedAt:    startedAt,
        endedAt:      endedAt,
        viewerCount:  viewerCount,
        likesCount:   likesCount,
        createdAt:    createdAt,
        sellerName:   sellerName,
        sellerAvatar: sellerAvatar,
      );
}
