// ignore_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// 🎯 Sửa lại đường dẫn tới AuthController cho đúng với cấu trúc của ông
import '../auth/AuthController.dart'; 

class ContactsController extends ChangeNotifier {
  // --- STATE (Trạng thái) ---
  int currentTab = 0; // 0: Bạn bè, 1: Nhóm
  String searchQuery = "";
  
  Map<String, dynamic>? selectedFriend;

  // --- KẾT NỐI API BACKEND ---
  final String _baseUrl = 'http://localhost:5034/api/contacts';
  
  List<dynamic> friendsList = [];
  bool isLoading = false;

  ContactsController() {
    _initData();
  }

  Future<void> _initData() async {
    await loadFriends();
    if (friendsList.isNotEmpty) {
      selectedFriend = friendsList[0];
    }
    notifyListeners();
  }

  // --- LOGIC GIAO DIỆN ---
  void switchTab(int index) {
    currentTab = index;
    notifyListeners();
  }

  void selectFriend(Map<String, dynamic> friend) {
    selectedFriend = friend;
    notifyListeners();
  }

  void updateSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  List<dynamic> get filteredFriends {
    if (searchQuery.isEmpty) return friendsList;
    return friendsList.where((f) {
      String name = (f['name'] ?? '').toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  // ==========================================
  // CÁC HÀM GỌI API XUỐNG C#
  // ==========================================
  
  // 1. Tải danh sách bạn bè
  Future<void> loadFriends() async {
    isLoading = true;
    notifyListeners();

    String currentUserId = await AuthController().getCurrentUserId();
    if (currentUserId != "guest") {
      try {
        final response = await http.get(Uri.parse('$_baseUrl/list/$currentUserId'));
        if (response.statusCode == 200) {
          friendsList = jsonDecode(response.body);
        }
      } catch (e) {
        debugPrint("Lỗi tải danh bạ: $e");
      }
    }
    
    isLoading = false;
    notifyListeners();
  }

  // 2. Tìm người dùng theo Email (Trả về Dữ liệu)
  Future<Map<String, dynamic>?> searchUser(String email) async {
    String currentUserId = await AuthController().getCurrentUserId();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/search?email=$email&currentUserId=$currentUserId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Lỗi tìm kiếm: $e");
    }
    return null;
  }

  // 3. Tìm người dùng trên toàn hệ thống (Cập nhật UI)
  Future<void> searchGlobalUser(BuildContext context, String email) async {
    if (email.trim().isEmpty) return;

    var result = await searchUser(email.trim());
    if (result != null) {
      selectedFriend = {
        'id': result['id'],
        'name': result['fullName'] ?? 'Người dùng',
        'avatarUrl': result['avatarUrl'] ?? '',
        'bio': result['bio'] ?? 'Chưa có thông tin',
        'isFriend': result['isFriend']
      };
      notifyListeners();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy người dùng này trên hệ thống!')));
      }
    }
  }

  // 4. Thêm / Hủy kết bạn
  Future<bool> toggleFriendStatus(String friendId) async {
    String currentUserId = await AuthController().getCurrentUserId();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': currentUserId, 'friendId': friendId}),
      );
      
      if (response.statusCode == 200) {
        await loadFriends(); 
        return jsonDecode(response.body)['isFriend'];
      }
    } catch (e) {
      debugPrint("Lỗi kết bạn: $e");
    }
    return false;
  }

  // Nút Kết bạn / Hủy bạn ở cột Phải màn hình
  Future<void> toggleFriendStatusFromPanel() async {
    if (selectedFriend == null) return;
    
    bool newStatus = await toggleFriendStatus(selectedFriend!['id']);
    selectedFriend!['isFriend'] = newStatus;
    notifyListeners();
  }
}