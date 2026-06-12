// ignore_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'CallScreenController.dart';
import '../../../core/services/signalr_service.dart';

class CallScreen extends StatefulWidget {
  final bool isVideoCall;
  final String userName;
  final String avatarUrl;
  final String conversationId;
  final bool isCaller;
  final String? initialOfferPayload;
  final Function(String messageType, String content) onCallEndedLog;

  const CallScreen({
    super.key,
    required this.isVideoCall,
    required this.userName,
    required this.avatarUrl,
    required this.conversationId,
    required this.isCaller,
    this.initialOfferPayload,
    required this.onCallEndedLog,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  late final CallScreenController _controller;
  late final AnimationController _rippleController;

  bool _hasRemoteStream = false;
  bool _isAccepted = false;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _controller = CallScreenController(
      conversationId: widget.conversationId,
      isVideoCall: widget.isVideoCall,
      signalR: SignalRService(),
      onCallEndedLog: widget.onCallEndedLog,
      onRemoteStreamAdded: () {
        if (!mounted || _isEnding) return;
        setState(() => _hasRemoteStream = true);
      },
      onCallEndedByRemote: () {
        _endCall(notifyRemote: false);
      },
    );

    if (widget.isCaller) {
      _isAccepted = true;
      unawaited(_startHardwareAndCall());
    }
  }

  // Khởi tạo camera, micro và bắt đầu xử lý WebRTC
  Future<void> _startHardwareAndCall() async {
    if (_isEnding || _controller.isClosed) return;

    await _controller.initHardware();

    if (!mounted || _isEnding || _controller.isClosed) return;

    setState(() {});

    if (widget.isCaller) {
      await _controller.startCallOffer();
    } else if (widget.initialOfferPayload != null) {
      await _controller.processInitialOffer(widget.initialOfferPayload!);
    }
  }

  // Chấp nhận cuộc gọi đến từ người khác
  void _acceptCallFromRemote() {
    if (_isEnding || _isAccepted) return;

    setState(() {
      _isAccepted = true;
    });

    unawaited(_startHardwareAndCall());
  }

  // Kết thúc cuộc gọi và đóng màn hình call
  Future<void> _endCall({bool notifyRemote = true}) async {
    if (_isEnding) return;

    _isEnding = true;

    if (mounted) {
      setState(() {});
    }

    await _controller.hangUp(
      widget.isCaller,
      notifyRemote: notifyRemote,
    );

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _rippleController.dispose();

    // Giải phóng camera, micro và renderer sau khi thoát màn hình gọi
    unawaited(_controller.disposeHardware());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (widget.isVideoCall && _hasRemoteStream && _isAccepted)
            RTCVideoView(
              _controller.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.avatarUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          if (!widget.isVideoCall || !_hasRemoteStream || !_isAccepted)
            Container(color: Colors.black.withValues(alpha: 0.7)),

          if (widget.isVideoCall &&
              !_controller.isCameraOff &&
              _isAccepted &&
              !_isEnding)
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(
                    _controller.localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),

          if (!_hasRemoteStream)
            Align(
              alignment: const Alignment(0, -0.25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120 + (_rippleController.value * 100),
                            height: 120 + (_rippleController.value * 100),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: 1.0 - _rippleController.value,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(widget.avatarUrl),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEnding
                        ? 'Đang kết thúc cuộc gọi...'
                        : _isAccepted
                            ? (widget.isVideoCall
                                ? 'Đang kết nối video...'
                                : 'Đang kết nối cuộc gọi thoại...')
                            : (widget.isVideoCall
                                ? 'Cuộc gọi video đến...'
                                : 'Cuộc gọi thoại đến...'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

          Align(
            alignment: const Alignment(0, 0.85),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: !_isAccepted
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      key: const ValueKey('incoming_actions'),
                      children: [
                        _buildControlButton(
                          icon: Icons.call_end_rounded,
                          color: Colors.red,
                          onTap: () => unawaited(_endCall()),
                          size: 64,
                          disabled: _isEnding,
                        ),
                        const SizedBox(width: 64),
                        _buildControlButton(
                          icon: Icons.call_rounded,
                          color: Colors.green,
                          onTap: _acceptCallFromRemote,
                          size: 64,
                          disabled: _isEnding,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      key: const ValueKey('active_actions'),
                      children: [
                        _buildControlButton(
                          icon: _controller.isMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          color: _controller.isMuted
                              ? Colors.redAccent
                              : Colors.white24,
                          onTap: () {
                            if (_isEnding) return;
                            _controller.toggleMute();
                            if (mounted) setState(() {});
                          },
                          disabled: _isEnding,
                        ),
                        const SizedBox(width: 32),
                        _buildControlButton(
                          icon: Icons.call_end_rounded,
                          color: Colors.red,
                          onTap: () => unawaited(_endCall()),
                          size: 68,
                          disabled: _isEnding,
                        ),
                        if (widget.isVideoCall) ...[
                          const SizedBox(width: 32),
                          _buildControlButton(
                            icon: _controller.isCameraOff
                                ? Icons.videocam_off_rounded
                                : Icons.videocam_rounded,
                            color: _controller.isCameraOff
                                ? Colors.redAccent
                                : Colors.white24,
                            onTap: () {
                              if (_isEnding) return;
                              _controller.toggleCamera();
                              if (mounted) setState(() {});
                            },
                            disabled: _isEnding,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Tạo nút điều khiển cuộc gọi như nhận, tắt, mute hoặc tắt camera
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}