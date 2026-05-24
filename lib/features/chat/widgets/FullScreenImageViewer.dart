import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag; 

  const FullScreenImageViewer({
    super.key, 
    required this.imageUrl, 
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nền đen mờ để tập trung vào ảnh
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: Stack(
        children: [
          // 1. Trình xem ảnh có thể Zoom/Pan
          Center(
            child: InteractiveViewer(
              panEnabled: true, // Cho phép kéo bạt ảnh sang các hướng
              minScale: 0.5,    // Thu nhỏ tối đa 50%
              maxScale: 4.0,    // Phóng to tối đa 400%
              child: Hero(
                tag: heroTag, // Tag này phải khớp với Tag ở màn hình Chat
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // 2. Các nút thao tác lơ lửng trên cùng (Overlay Controls)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút Đóng
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  
                  // Nút Tải xuống / Lưu ảnh
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 24),
                      onPressed: () {
                        // Hiển thị thông báo tải xuống (Sau này nối logic tải file vào đây)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đang tải ảnh xuống...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
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
}