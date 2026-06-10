// ignore_file: file_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/services/signalr_service.dart';

class CallScreenController {
  final String conversationId;
  final bool isVideoCall;
  final SignalRService signalR;
  final Function(String messageType, String content) onCallEndedLog;
  final VoidCallback onRemoteStreamAdded;
  final VoidCallback onCallEndedByRemote;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool isMuted = false;
  bool isCameraOff = false;
  DateTime? callStartTime;

  bool _isDisposed = false;
  bool _isEnding = false;
  bool _renderersInitialized = false;

  bool _hasRemoteDescription = false;
  bool _hasHandledOffer = false;
  bool _hasHandledAnswer = false;

  final List<RTCIceCandidate> _pendingIceCandidates = [];

  bool get isClosed => _isDisposed || _isEnding;

  CallScreenController({
    required this.conversationId,
    required this.isVideoCall,
    required this.signalR,
    required this.onCallEndedLog,
    required this.onRemoteStreamAdded,
    required this.onCallEndedByRemote,
  });

  Future<void> initHardware() async {
    if (_isDisposed || _isEnding) return;

    debugPrint('🎥 Đang init renderer/camera/mic...');

    try {
      if (!_renderersInitialized) {
        await localRenderer.initialize();
        await remoteRenderer.initialize();
        _renderersInitialized = true;
      }
    } catch (e) {
      debugPrint('❌ Lỗi initialize RTCVideoRenderer: $e');
      onCallEndedByRemote();
      return;
    }

    if (_isDisposed || _isEnding) return;

    final mediaConstraints = <String, dynamic>{
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideoCall
          ? {
              'facingMode': 'user',
              'width': {'ideal': 320},
              'height': {'ideal': 180},
              'frameRate': {'ideal': 30, 'max': 30},
            }
          : false,
    };

    MediaStream? stream;

    try {
      stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    } catch (e) {
      debugPrint('❌ Không mở được camera/mic: $e');
      onCallEndedByRemote();
      return;
    }

    if (_isDisposed || _isEnding) {
      await _disposeStreamSafely(stream, 'late localStream');
      return;
    }

    _localStream = stream;
    localRenderer.srcObject = _localStream;

    await _createPeerConnection();

    if (_isDisposed || _isEnding) return;

    signalR.webRTCSignal.removeListener(_webRTCSignalListener);
    signalR.webRTCSignal.addListener(_webRTCSignalListener);

    debugPrint('✅ Init phần cứng gọi điện xong');
  }

  void _webRTCSignalListener() {
    if (_isDisposed || _isEnding) return;

    final signal = signalR.webRTCSignal.value;
    if (signal == null) return;

    final msgConvId = signal['conversationId']?.toString().toLowerCase();
    if (msgConvId != conversationId.toLowerCase()) return;

    final type = signal['type']?.toString() ?? '';
    final content = signal['content']?.toString() ?? '';

    if (type != 'ice') {
      debugPrint('📞 Nhận WebRTC signal: $type');
    }

    if (type == 'offer_video' || type == 'offer_voice') {
      unawaited(_handleIncomingSignal('offer', content));
    } else if (type == 'answer') {
      unawaited(_handleIncomingSignal('answer', content));
    } else if (type == 'ice') {
      unawaited(_handleIncomingSignal('ice', content));
    } else if (type == 'end') {
      // Remote đã tắt cuộc gọi.
      // Không gửi lại signal 'end' nữa để tránh vòng lặp và double-cleanup.
      onCallEndedByRemote();
    }
  }

  Future<void> _createPeerConnection() async {
    if (_isDisposed || _isEnding) return;

    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    final pc = await createPeerConnection(configuration, constraints);

    if (_isDisposed || _isEnding) {
      try {
        await pc.close().timeout(const Duration(seconds: 2));
      } catch (_) {}

      try {
        await pc.dispose().timeout(const Duration(seconds: 2));
      } catch (_) {}

      return;
    }

    _peerConnection = pc;

    pc.onSignalingState = (state) {
      if (_isDisposed || _isEnding) return;
      debugPrint('🔁 SignalingState: $state');
    };

    pc.onIceGatheringState = (state) {
      if (_isDisposed || _isEnding) return;
      debugPrint('🧊 IceGatheringState: $state');
    };

    pc.onIceConnectionState = (state) {
      if (_isDisposed || _isEnding) return;
      debugPrint('🧊 IceConnectionState: $state');
    };

    pc.onConnectionState = (state) {
      if (_isDisposed || _isEnding) return;
      debugPrint('🌐 PeerConnectionState: $state');
    };

    final tracks = _localStream?.getTracks() ?? [];
    for (final track in tracks) {
      if (_isDisposed || _isEnding) return;
      await pc.addTrack(track, _localStream!);
    }

    pc.onTrack = (event) {
      if (_isDisposed || _isEnding) return;

      debugPrint('📡 Nhận remote track: ${event.track.kind}');

      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        remoteRenderer.srcObject = _remoteStream;
        callStartTime ??= DateTime.now();
        onRemoteStreamAdded();
      }
    };

    pc.onIceCandidate = (candidate) {
      if (_isDisposed || _isEnding) return;

      final candidateMap = candidate.toMap();
      final candidateText = candidateMap['candidate']?.toString();

      if (candidateText == null || candidateText.isEmpty) return;

      unawaited(
        signalR
            .sendCallSignal(conversationId, 'ice', jsonEncode(candidateMap))
            .timeout(const Duration(seconds: 2))
            .catchError((e) {
          debugPrint('⚠️ Gửi ICE candidate lỗi/timeout: $e');
        }),
      );
    };

    debugPrint('✅ PeerConnection đã tạo xong');
  }

  Future<void> startCallOffer() async {
    if (_isDisposed || _isEnding) return;

    final pc = _peerConnection;

    if (pc == null) {
      debugPrint('❌ Không thể tạo offer vì PeerConnection null');
      return;
    }

    try {
      final offer = await pc.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideoCall,
      });

      if (_isDisposed || _isEnding) return;

      await pc.setLocalDescription(offer);

      if (_isDisposed || _isEnding) return;

      final offerType = isVideoCall ? 'offer_video' : 'offer_voice';

      await signalR
          .sendCallSignal(conversationId, offerType, jsonEncode(offer.toMap()))
          .timeout(const Duration(seconds: 4));

      debugPrint('📤 Đã gửi $offerType');
    } catch (e) {
      debugPrint('❌ Lỗi tạo/gửi offer: $e');
    }
  }

  Future<void> processInitialOffer(String offerPayload) async {
    if (_isDisposed || _isEnding) return;
    await _handleIncomingSignal('offer', offerPayload);
  }

  Future<void> _handleIncomingSignal(String type, String payloadStr) async {
    if (_isDisposed || _isEnding) return;
    if (payloadStr.isEmpty) return;

    final pc = _peerConnection;
    if (pc == null) return;

    try {
      final payload = jsonDecode(payloadStr);

      if (type == 'offer') {
        if (_hasHandledOffer) return;
        _hasHandledOffer = true;

        await pc.setRemoteDescription(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );

        if (_isDisposed || _isEnding) return;

        _hasRemoteDescription = true;
        await _flushPendingIceCandidates();

        if (_isDisposed || _isEnding) return;

        final answer = await pc.createAnswer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': isVideoCall,
        });

        if (_isDisposed || _isEnding) return;

        await pc.setLocalDescription(answer);

        if (_isDisposed || _isEnding) return;

        await signalR
            .sendCallSignal(
              conversationId,
              'answer',
              jsonEncode(answer.toMap()),
            )
            .timeout(const Duration(seconds: 4));

        debugPrint('📤 Đã gửi answer');
      } else if (type == 'answer') {
        if (_hasHandledAnswer) return;
        _hasHandledAnswer = true;

        await pc.setRemoteDescription(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );

        if (_isDisposed || _isEnding) return;

        _hasRemoteDescription = true;
        await _flushPendingIceCandidates();

        debugPrint('✅ Đã set remote answer');
      } else if (type == 'ice') {
        final candidate = RTCIceCandidate(
          payload['candidate'],
          payload['sdpMid'],
          payload['sdpMLineIndex'],
        );

        if (!_hasRemoteDescription) {
          _pendingIceCandidates.add(candidate);
          return;
        }

        await pc.addCandidate(candidate);
      }
    } catch (e) {
      debugPrint('❌ Lỗi xử lý WebRTC signal [$type]: $e');
    }
  }

  Future<void> _flushPendingIceCandidates() async {
    if (!_hasRemoteDescription) return;
    if (_pendingIceCandidates.isEmpty) return;

    final pc = _peerConnection;
    if (pc == null) return;

    final candidates = List<RTCIceCandidate>.from(_pendingIceCandidates);
    _pendingIceCandidates.clear();

    for (final candidate in candidates) {
      if (_isDisposed || _isEnding) return;

      try {
        await pc.addCandidate(candidate);
      } catch (e) {
        debugPrint('⚠️ Add pending ICE lỗi: $e');
      }
    }
  }

  void toggleMute() {
    if (_isDisposed || _isEnding) return;

    isMuted = !isMuted;

    final audioTracks = _localStream?.getAudioTracks() ?? [];
    if (audioTracks.isNotEmpty) {
      audioTracks.first.enabled = !isMuted;
    }

    debugPrint(isMuted ? '🔇 Đã tắt mic' : '🎙️ Đã bật mic');
  }

  void toggleCamera() {
    if (_isDisposed || _isEnding) return;
    if (!isVideoCall) return;

    isCameraOff = !isCameraOff;

    final videoTracks = _localStream?.getVideoTracks() ?? [];
    if (videoTracks.isNotEmpty) {
      videoTracks.first.enabled = !isCameraOff;
    }

    debugPrint(isCameraOff ? '📷 Đã tắt camera' : '📷 Đã bật camera');
  }

  Future<void> hangUp(
    bool isCaller, {
    bool notifyRemote = true,
  }) async {
    if (_isEnding && _isDisposed) return;

    final shouldRunFirstTime = !_isEnding;
    _isEnding = true;

    if (shouldRunFirstTime && notifyRemote) {
      unawaited(
        signalR
            .sendCallSignal(conversationId, 'end', 'Ended')
            .timeout(const Duration(seconds: 2))
            .catchError((e) {
          debugPrint('⚠️ Gửi signal end lỗi/timeout: $e');
        }),
      );
    }

    if (shouldRunFirstTime) {
      final callType = isVideoCall ? 'call_video' : 'call_voice';
      String messageContent;

      if (callStartTime == null) {
        messageContent = isCaller ? 'Bạn đã hủy cuộc gọi.' : 'Cuộc gọi nhỡ.';
      } else {
        final duration = DateTime.now().difference(callStartTime!);
        final min = duration.inMinutes.toString().padLeft(2, '0');
        final sec = (duration.inSeconds % 60).toString().padLeft(2, '0');
        messageContent = 'Cuộc gọi kết thúc. Thời lượng: $min:$sec';
      }

      try {
        onCallEndedLog(callType, messageContent);
      } catch (e) {
        debugPrint('⚠️ Ghi log cuộc gọi lỗi: $e');
      }
    }

    await disposeHardware();
  }

  Future<void> disposeHardware() async {
    if (_isDisposed) return;

    _isDisposed = true;
    _isEnding = true;

    debugPrint('🛑 Bắt đầu cleanup WebRTC desktop...');

    signalR.webRTCSignal.removeListener(_webRTCSignalListener);

    final pc = _peerConnection;
    final localStream = _localStream;
    final remoteStream = _remoteStream;

    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;

    _pendingIceCandidates.clear();

    // Chặn callback native bắn ngược vào UI trong lúc dispose.
    try {
      pc?.onTrack = null;
      pc?.onIceCandidate = null;
      pc?.onSignalingState = null;
      pc?.onIceGatheringState = null;
      pc?.onIceConnectionState = null;
      pc?.onConnectionState = null;
    } catch (e) {
      debugPrint('⚠️ Gỡ callback PeerConnection lỗi: $e');
    }

    // Detach stream khỏi renderer trước để GPU không còn dựng frame.
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (e) {
      debugPrint('⚠️ Detach renderer lỗi: $e');
    }

    await Future.delayed(const Duration(milliseconds: 50));

    // Close peer connection trước.
    try {
      await pc?.close().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('⚠️ close PeerConnection lỗi/timeout: $e');
    }

    await _disposeStreamSafely(localStream, 'localStream');
    await _disposeStreamSafely(remoteStream, 'remoteStream');

    // Dispose peer connection sau khi close + dispose stream.
    try {
      await pc?.dispose().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('⚠️ dispose PeerConnection lỗi/timeout: $e');
    }

    await Future.delayed(const Duration(milliseconds: 50));

    if (_renderersInitialized) {
      try {
        await localRenderer.dispose().timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('⚠️ dispose localRenderer lỗi/timeout: $e');
      }

      try {
        await remoteRenderer.dispose().timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('⚠️ dispose remoteRenderer lỗi/timeout: $e');
      }

      _renderersInitialized = false;
    }

    debugPrint('✅ Cleanup WebRTC desktop xong');
  }

  Future<void> _disposeStreamSafely(MediaStream? stream, String name) async {
    if (stream == null) return;

    try {
      final tracks = stream.getTracks();

      for (final track in tracks) {
        try {
          await track.stop().timeout(const Duration(seconds: 1));
        } catch (e) {
          debugPrint('⚠️ stop track $name lỗi/timeout: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ getTracks $name lỗi: $e');
    }

    try {
      await stream.dispose().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('⚠️ dispose $name lỗi/timeout: $e');
    }
  }
}