// ignore_file: file_names
import 'package:flutter/material.dart';

// Mô hình dữ liệu Bài viết (Đã thiết kế lại để sẵn sàng đón dữ liệu từ C# Database)
class Post {
  final String id;
  
  // 🎯 QUAN TRỌNG: Phải mang theo ID của người đăng để khi nhấn vào Avatar còn biết là mở Profile của ai!
  final String userId; 
  
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
    required this.id, 
    required this.userId, // 🎯
    required this.userName, 
    required this.userAvatar, 
    required this.timeAgo, 
    this.content, 
    required this.mediaType, 
    this.mediaUrl, 
    this.likes = 0, 
    this.comments = 0, 
    this.isLiked = false
  });
}

class TimelineController extends ChangeNotifier {
  // Dữ liệu giả lập (Sau này sẽ fetch từ Database C# PostgreSQL)
  // Tui đã nhét thử ID người đăng vào để ông test Click mở Profile
  final List<Post> posts = [
    Post(
      id: 'p1', 
      userId: 'user-001', // 🎯 Giả lập ID thật
      userName: 'Trần Thị B', 
      userAvatar: 'https://i.pravatar.cc/150?img=5', 
      timeAgo: '15 phút trước', 
      content: 'Đi cà phê', 
      mediaType: 'image', 
      mediaUrl: 'https://picsum.photos/seed/cafe/600/400', 
      likes: 12, comments: 3
    ),
    Post(
      id: 'p2', 
      userId: 'user-002', // 🎯 Giả lập ID thật
      userName: 'Lê Hoàng C', 
      userAvatar: 'https://i.pravatar.cc/150?img=8', 
      timeAgo: '2 giờ trước', 
      content: 'Vừa làm xong việc', 
      mediaType: 'none', likes: 45, comments: 10
    ),
    Post(
      id: 'p3', 
      userId: 'user-003', // 🎯 Giả lập ID thật
      userName: 'Nguyễn Văn A', 
      userAvatar: 'https://i.pravatar.cc/150?img=12', 
      timeAgo: 'Hôm qua', 
      content: 'Chill cùng bản nhạc này', 
      mediaType: 'music', likes: 8, comments: 1
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