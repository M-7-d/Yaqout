import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../data/repositories/stream_repository_impl.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/live_stream_message_entity.dart';
import '../../domain/repositories/stream_repository.dart';
import '../../../../shared/providers/shared_providers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final streamRepositoryProvider = Provider<StreamRepository>((ref) {
  return StreamRepositoryImpl(ref.read(supabaseClientProvider));
});

final liveStreamsProvider = StreamProvider<List<LiveStreamEntity>>((ref) {
  final repo = ref.read(streamRepositoryProvider);
  final client = ref.read(supabaseClientProvider);
  
  // 1. Clean up immediately when the provider starts
  client.rpc('cleanup_stale_live_streams').catchError((_) => null);
  
  // 2. Set up a periodic background cleanup every 60 seconds.
  // This fully replaces the need for pg_cron as long as the app is running!
  final timer = Timer.periodic(const Duration(seconds: 60), (_) {
    client.rpc('cleanup_stale_live_streams').catchError((_) => null);
  });
  
  ref.onDispose(() => timer.cancel());
  
  return repo.watchLiveStreams();
});
final singleLiveStreamProvider = StreamProvider.family<LiveStreamEntity, String>((ref, id) {
  return ref.read(streamRepositoryProvider).watchStreamById(id);
});

final liveStreamMessagesProvider = StreamProvider.family<List<LiveStreamMessageEntity>, String>((ref, streamId) {
  return ref.read(streamRepositoryProvider).watchMessages(streamId);
});

final userBlockStreamProvider = StreamProvider.family<bool, ({String streamId, String userId})>((ref, arg) {
  return ref.read(streamRepositoryProvider).watchUserBlock(arg.streamId, arg.userId);
});

// ── Agora Engine State ─────────────────────────────────────────────────────────
class AgoraState {
  final bool isJoined;
  final bool isMuted;
  final bool isCameraOff;
  final List<int> remoteUids;
  final String? error;

  const AgoraState({
    this.isJoined    = false,
    this.isMuted     = false,
    this.isCameraOff = false,
    this.remoteUids  = const [],
    this.error,
  });

  AgoraState copyWith({
    bool?        isJoined,
    bool?        isMuted,
    bool?        isCameraOff,
    List<int>?   remoteUids,
    String?      error,
  }) =>
      AgoraState(
        isJoined:    isJoined    ?? this.isJoined,
        isMuted:     isMuted     ?? this.isMuted,
        isCameraOff: isCameraOff ?? this.isCameraOff,
        remoteUids:  remoteUids  ?? this.remoteUids,
        error:       error,
      );
}

class AgoraNotifier extends StateNotifier<AgoraState> {
  final StreamRepository _streamRepo;
  RtcEngine? _engine;
  Timer? _heartbeatTimer;

  AgoraNotifier(this._streamRepo) : super(const AgoraState());

  Future<void> joinAsHost(String streamId, String channelName) async {
    await _init(channelName, isHost: true, streamId: streamId);
  }

  Future<void> joinAsViewer(String streamId, String channelName) async {
    await _init(channelName, isHost: false, streamId: streamId);
  }

  Future<void> _init(
    String channelName, {
    required bool isHost,
    required String streamId,
  }) async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: dotenv.env['AGORA_APP_ID'] ?? '',
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          state = state.copyWith(isJoined: true);
          if (isHost) {
            _streamRepo.updateStreamStatus(streamId, 'live');
            // Start heartbeat: server will auto-end the stream if
            // heartbeat stops (e.g. app killed).
            _startHeartbeat(streamId);
          } else {
            _streamRepo.incrementViewerCount(streamId);
          }
        },
        onUserJoined: (_, uid, __) {
          state = state.copyWith(remoteUids: [...state.remoteUids, uid]);
        },
        onUserOffline: (_, uid, __) {
          state = state.copyWith(
            remoteUids: state.remoteUids.where((id) => id != uid).toList(),
          );
        },
        onError: (err, msg) => state = state.copyWith(error: msg),
      ));

      await _engine!.setClientRole(
        role: isHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );

      // Enable both audio and video for all participants so the SDK
      // can send/receive media frames correctly.
      await _engine!.enableAudio();
      await _engine!.enableVideo();

      if (isHost) {
        // Set a reliable video encoder configuration so the SDK
        // knows which resolution/frame-rate to capture.
        await _engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 720, height: 1280),
            frameRate: 15,
            bitrate: 0, // SDK default
          ),
        );
      }

      // Fetch token BEFORE starting preview / joining channel so there
      // is no race between preview render and channel auth.
      final token = await _streamRepo.getAgoraToken(
        channelName, 0, isHost: isHost,
      );

      if (isHost) {
        // Start preview BEFORE joining so the local camera starts capturing
        await _engine!.startPreview();
        // Switch to back camera as default
        await _engine!.switchCamera();
      }

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: isHost
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
          publishCameraTrack: isHost,
          publishMicrophoneTrack: isHost,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleMute() async {
    final muted = !state.isMuted;
    await _engine?.muteLocalAudioStream(muted);
    state = state.copyWith(isMuted: muted);
  }

  Future<void> toggleCamera() async {
    final off = !state.isCameraOff;
    await _engine?.enableLocalVideo(!off);
    state = state.copyWith(isCameraOff: off);
  }

  Future<void> toggleSwitchCamera() async {
    if (state.isCameraOff) return;
    await _engine?.switchCamera();
  }

  Future<void> leave(String streamId, {required bool isHost}) async {
    _stopHeartbeat();
    await _engine?.leaveChannel();
    await _engine?.release();
    if (isHost) {
      await _streamRepo.updateStreamStatus(streamId, 'ended');
    } else {
      await _streamRepo.decrementViewerCount(streamId);
    }
    state = const AgoraState();
    _engine = null;
  }

  /// Sends a heartbeat to the server every 30 seconds.
  /// If the app is killed, the timer dies with it — the server-side
  /// cleanup function detects the missing heartbeat and ends the stream.
  void _startHeartbeat(String streamId) {
    _stopHeartbeat();
    // Send first heartbeat immediately
    _streamRepo.updateHeartbeat(streamId);
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _streamRepo.updateHeartbeat(streamId),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  RtcEngine? get engine => _engine;
}

final agoraProvider =
    StateNotifierProvider<AgoraNotifier, AgoraState>((ref) {
  return AgoraNotifier(ref.read(streamRepositoryProvider));
});
