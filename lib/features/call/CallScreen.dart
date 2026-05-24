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
  // Thêm SingleTickerProviderStateMixin để chạy Animation
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isCameraOff = false;

  // Controller quản lý hiệu ứng sóng âm (Ripple effect)
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    // Cài đặt hiệu ứng lặp đi lặp lại mỗi 1.5 giây
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Nền đen sâu
      body: Stack(
        children: [
          // 1. Nền: Avatar làm mờ hoặc hình ảnh Camera
          if (widget.isVideoCall && !_isCameraOff)
            Container(color: Colors.grey[900]) 
          else
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: NetworkImage(widget.avatarUrl), fit: BoxFit.cover),
              ),
            ),
          
          // Lớp phủ đen làm nổi bật giao diện
          Container(color: Colors.black.withValues(alpha: 0.7)),

          // 2. Trung tâm: Avatar và Hiệu ứng Đổ chuông
          Align(
            alignment: const Alignment(0, -0.3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Khối Animation Sóng âm tỏa ra
                AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Vòng sóng tỏa ra
                        Container(
                          width: 120 + (_rippleController.value * 100), // Phóng to dần
                          height: 120 + (_rippleController.value * 100),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Mờ dần khi phóng to
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 1.0 - _rippleController.value), 
                              width: 2
                            ),
                          ),
                        ),
                        // Avatar tĩnh ở giữa
                        CircleAvatar(radius: 60, backgroundImage: NetworkImage(widget.avatarUrl)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(widget.userName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(widget.isVideoCall ? 'Đang gọi video...' : 'Đang đổ chuông...', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
          ),

          // 3. Các nút điều khiển lơ lửng
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
                  size: 64, // Nút cúp máy to hơn một chút
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