// ignore_file: file_names
import 'package:flutter/material.dart';

// Model mô phỏng dữ liệu Bạn bè
class Friend {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final String bio;
  final String phone;

  Friend({required this.id, required this.name, required this.avatarUrl, required this.isOnline, required this.bio, required this.phone});
}

// Model mô phỏng dữ liệu Nhóm
class Group {
  final String id;
  final String name;
  final String avatarUrl;
  final int memberCount;
  final String description;

  Group({required this.id, required this.name, required this.avatarUrl, required this.memberCount, required this.description});
}

class ContactsController extends ChangeNotifier {
  // --- STATE (Trạng thái) ---
  int currentTab = 0; // 0: Bạn bè, 1: Nhóm
  String searchQuery = "";
  
  Friend? selectedFriend;
  Group? selectedGroup;

  // --- DỮ LIỆU GIẢ LẬP (MOCK DATA) ---
  final List<Friend> allFriends = [
    Friend(id: '1', name: 'Nguyễn Văn A', avatarUrl: 'https://i.pravatar.cc/150?img=12', isOnline: true, bio: 'Đang code sấp mặt...', phone: '+84 987 654 321'),
    Friend(id: '2', name: 'Trần Thị B', avatarUrl: 'https://i.pravatar.cc/150?img=5', isOnline: false, bio: 'Thích đi du lịch ✈️', phone: '+84 123 456 789'),
    Friend(id: '3', name: 'Lê Hoàng C', avatarUrl: 'https://i.pravatar.cc/150?img=8', isOnline: true, bio: 'Flutter Developer', phone: '+84 333 222 111'),
    Friend(id: '4', name: 'Phạm D', avatarUrl: 'https://i.pravatar.cc/150?img=15', isOnline: false, bio: 'Busy', phone: '+84 999 888 777'),
  ];

  final List<Group> allGroups = [
    Group(id: 'g1', name: 'Hội Coder Cú Đêm', avatarUrl: 'https://i.pravatar.cc/150?img=24', memberCount: 120, description: 'Nơi giao lưu học hỏi về C#, Python, Flutter'),
    Group(id: 'g2', name: 'Gia đình', avatarUrl: 'https://i.pravatar.cc/150?img=32', memberCount: 5, description: 'Nhóm gia đình nhỏ'),
    Group(id: 'g3', name: 'Đồ án Nhóm', avatarUrl: 'https://i.pravatar.cc/150?img=11', memberCount: 10, description: 'Thảo luận đồ án môn học AI'),
  ];

  // Khởi tạo mặc định chọn người đầu tiên cho giao diện Desktop đỡ bị trống
  ContactsController() {
    if (allFriends.isNotEmpty) selectedFriend = allFriends[0];
    if (allGroups.isNotEmpty) selectedGroup = allGroups[0];
  }

  // --- LOGIC FUNCTIONS ---
  void switchTab(int index) {
    currentTab = index;
    notifyListeners();
  }

  void selectFriend(Friend friend) {
    selectedFriend = friend;
    notifyListeners();
  }

  void selectGroup(Group group) {
    selectedGroup = group;
    notifyListeners();
  }

  void updateSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  // Hàm lọc danh sách dựa trên ô tìm kiếm
  List<Friend> get filteredFriends => allFriends
      .where((f) => f.name.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();

  List<Group> get filteredGroups => allGroups
      .where((g) => g.name.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();
}