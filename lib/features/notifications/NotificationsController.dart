// ignore_file: file_names
import 'package:flutter/material.dart';

// Cấu trúc một tin nhắn trong hộp thông báo tập trung
class InboxMessage {
  final String id;
  final String senderName;
  final String avatarUrl;
  final String groupName; // Nếu là chat cá nhân thì để trống, chat nhóm thì điền vào
  final String snippet;
  final String timeStamp;
  bool isRead;
  final bool isMention; // Có gắn thẻ tag tên mình hay không (VD: @Nam)

  InboxMessage({
    required this.id, required this.senderName, required this.avatarUrl, 
    this.groupName = "", required this.snippet, required this.timeStamp, 
    this.isRead = false, this.isMention = false
  });
}

class NotificationsController extends ChangeNotifier {
  // 0: Chưa đọc, 1: Đã đọc, 2: Được nhắc đến (@)
  int currentFilterIndex = 0; 

  // Danh sách tin nhắn tổng hợp từ tất cả các chat room đổ về
  final List<InboxMessage> _allInboxMessages = [
    InboxMessage(
      id: 'm1', senderName: 'Lê Hoàng C', avatarUrl: 'https://i.pravatar.cc/150?img=8',
      groupName: 'Hội Coder Cú Đêm', snippet: '@Nam xem hộ tui cái lỗi kết nối này với!',
      timeStamp: '3 phút trước', isMention: true
    ),
    InboxMessage(
      id: 'm2', senderName: 'Nguyễn Văn A', avatarUrl: 'https://i.pravatar.cc/150?img=12',
      snippet: 'Lát nữa có đi tập gym không ông ơi?', timeStamp: '12 phút trước'
    ),
    InboxMessage(
      id: 'm3', senderName: 'Trần Thị B', avatarUrl: 'https://i.pravatar.cc/150?img=5',
      groupName: 'Đồ án Nhóm AI', snippet: 'Tui vừa up bản báo cáo lên Supabase rồi nha.',
      timeStamp: '1 giờ trước'
    ),
    InboxMessage(
      id: 'm4', senderName: 'Phạm D', avatarUrl: 'https://i.pravatar.cc/150?img=15',
      snippet: 'Ok bạn nhé, cảm ơn nhiều.', timeStamp: 'Hôm qua', isRead: true
    ),
  ];

  // Lọc danh sách hiển thị dựa vào Filter Tab đang chọn
  List<InboxMessage> get filteredMessages {
    if (currentFilterIndex == 0) {
      return _allInboxMessages.where((m) => !m.isRead).toList(); // Chưa đọc
    } else if (currentFilterIndex == 1) {
      return _allInboxMessages.where((m) => m.isRead).toList(); // Đã đọc
    } else {
      return _allInboxMessages.where((m) => m.isMention && !m.isRead).toList(); // Được tag tên
    }
  }

  // Thay đổi bộ lọc (Chưa đọc / Đã đọc / Nhắc đến)
  void changeFilter(int index) {
    currentFilterIndex = index;
    notifyListeners();
  }

  // Đánh dấu nhanh một tin nhắn là đã đọc (Mark as Read)
  void markAsRead(String id) {
    final message = _allInboxMessages.firstWhere((m) => m.id == id);
    message.isRead = true;
    notifyListeners();
  }

  // Đánh dấu đọc toàn bộ tin nhắn chưa đọc (Clear All Unread)
  void markAllAsRead() {
    for (var m in _allInboxMessages) {
      m.isRead = true;
    }
    notifyListeners();
  }
}