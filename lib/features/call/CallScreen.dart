// ignore_file: file_names
import 'package:flutter/material.dart';

class CallScreen extends StatefulWidget {
  final bool isVideoCall;
  final String userName;
  final String avatarUrl;

  const CallScreen({
    super.key, 
    required this.isVideoCall, 
    required this.userName, 
    required this.avatarUrl
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isCameraOff = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Nền đen cho sang trọng
      body: Stack(
        children: [
          // 1. Nền: Avatar làm mờ hoặc hình ảnh Camera
          if (widget.isVideoCall && !_isCameraOff)
            Container(color: Colors.grey[900]) // Chỗ này sau sẽ gắn Camera Stream
          else
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: NetworkImage(widget.avatarUrl), fit: BoxFit.cover),
              ),
              // Hiệu ứng Blur cho sang
            ),
          
          // 2. Lớp phủ đen làm nổi bật text
          Container(color: Colors.black.withValues(alpha: 0.5)),

          // 3. Thông tin người gọi
          Align(
            alignment: const Alignment(0, -0.4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 60, backgroundImage: NetworkImage(widget.avatarUrl)),
                const SizedBox(height: 24),
                Text(widget.userName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(widget.isVideoCall ? 'Đang gọi video...' : 'Đang gọi thoại...', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
          ),

          // 4. Các nút điều khiển lơ lửng (Floating Controls)
          Align(
            alignment: const Alignment(0, 0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: _isMuted ? Colors.red : Colors.white24,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),
                const SizedBox(width: 32),
                _buildControlButton(
                  icon: Icons.call_end_rounded,
                  color: Colors.redAccent,
                  onTap: () => Navigator.pop(context),
                  size: 64,
                ),
                if (widget.isVideoCall) ...[
                  const SizedBox(width: 32),
                  _buildControlButton(
                    icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    color: _isCameraOff ? Colors.red : Colors.white24,
                    onTap: () => setState(() => _isCameraOff = !_isCameraOff),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required VoidCallback onTap, double size = 56}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}