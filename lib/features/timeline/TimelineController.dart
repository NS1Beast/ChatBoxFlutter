// ignore_file: file_names
import 'package:flutter/material.dart';

// Mô hình dữ liệu Bài viết
class Post {
  final String id;
  final String userName;
  final String userAvatar;
  final String timeAgo;
  final String? content;
  final String mediaType; // 'image', 'video', 'music', 'gif', 'none'
  final String? mediaUrl;
  int likes;
  int comments;
  bool isLiked;

  Post({
    required this.id, required this.userName, required this.userAvatar, 
    required this.timeAgo, this.content, required this.mediaType, 
    this.mediaUrl, this.likes = 0, this.comments = 0, this.isLiked = false
  });
}

class TimelineController extends ChangeNotifier {
  // Dữ liệu giả lập (Sau này sẽ fetch từ Database Supabase/PostgreSQL)
  final List<Post> posts = [
    Post(
      id: 'p1', userName: 'Trần Thị B', userAvatar: 'https://i.pravatar.cc/150?img=5', 
      timeAgo: '15 phút trước', content: 'Hôm nay trời đẹp quá! Đi cafe thôi ☕️', 
      mediaType: 'image', mediaUrl: 'https://picsum.photos/seed/cafe/600/400', 
      likes: 12, comments: 3
    ),
    Post(
      id: 'p2', userName: 'Lê Hoàng C', userAvatar: 'https://i.pravatar.cc/150?img=8', 
      timeAgo: '2 giờ trước', content: 'Vừa hoàn thành xong module UI bằng Flutter. Cảm giác thật tuyệt vời! Mượt mà và xịn xò 🚀', 
      mediaType: 'none', likes: 45, comments: 10
    ),
    Post(
      id: 'p3', userName: 'Nguyễn Văn A', userAvatar: 'https://i.pravatar.cc/150?img=12', 
      timeAgo: 'Hôm qua', content: 'Chill cùng bản nhạc này nhé mọi người 🎵', 
      mediaType: 'music', likes: 8, comments: 1
    ),
    Post(
      id: 'p4', userName: 'Hội Coder Cú Đêm', userAvatar: 'https://i.pravatar.cc/150?img=24', 
      timeAgo: '2 ngày trước', content: 'Thử test xem ảnh GIF có chạy mượt không nào!', 
      mediaType: 'gif', mediaUrl: 'https://i.giphy.com/media/xT9IgzoKnwFNmISR8I/giphy.webp', 
      likes: 102, comments: 15
    ),
  ];

  // Logic thả tim
  void toggleLike(String postId) {
    final post = posts.firstWhere((p) => p.id == postId);
    post.isLiked = !post.isLiked;
    post.likes += post.isLiked ? 1 : -1;
    notifyListeners();
  }
}