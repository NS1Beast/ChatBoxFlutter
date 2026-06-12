// ignore_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/AuthController.dart'; 

class ContactsController extends ChangeNotifier {
  // --- STATE (Trạng thái) ---
  int currentTab = 0; // 0: Bạn bè, 1: Nhóm
  String searchQuery = "";
  
  Map<String, dynamic>? selectedFriend;
  Map<String, dynamic>? selectedGroup; // 🎯 THÊM BIẾN QUẢN LÝ NHÓM ĐANG CHỌN

  // --- KẾT NỐI API BACKEND ---
  final String _baseUrl = 'http://localhost:5034/api/contacts';
  final String _groupApiUrl = 'http://localhost:5034/api/Conversations'; // 🎯 THÊM URL NHÓM
  
  List<dynamic> friendsList = [];
  List<dynamic> groupsList = []; // 🎯 THÊM LIST NHÓM
  bool isLoading = false;

  ContactsController() {
    _initData();
  }

  Future<void> _initData() async {
    await loadFriends();
    await loadGroups(); // 🎯 GỌI TẢI DANH SÁCH NHÓM
    if (friendsList.isNotEmpty) {
      selectedFriend = friendsList[0];
    }
    notifyListeners();
  }

  // --- LOGIC GIAO DIỆN ---
  void switchTab(int index) {
    currentTab = index;
    // Tự động chọn item đầu tiên khi chuyển tab cho UI khỏi trống
    if (index == 0 && friendsList.isNotEmpty) selectedFriend = friendsList[0];
    if (index == 1 && groupsList.isNotEmpty) selectedGroup = groupsList[0];
    notifyListeners();
  }

  void selectFriend(Map<String, dynamic> friend) {
    selectedFriend = friend;
    notifyListeners();
  }

  void selectGroup(Map<String, dynamic> group) {
    selectedGroup = group;
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

  List<dynamic> get filteredGroups {
    if (searchQuery.isEmpty) return groupsList;
    return groupsList.where((g) {
      String name = (g['groupName'] ?? '').toLowerCase();
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

  // 🎯 2. Tải danh sách Nhóm
  Future<void> loadGroups() async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$_groupApiUrl/my-groups'),
        headers: { 'Authorization': 'Bearer $token' }
      );
      
      if (response.statusCode == 200) {
        groupsList = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách nhóm: $e");
    }
    notifyListeners();
  }

  // 3. Tìm người dùng theo Email
  Future<Map<String, dynamic>?> searchUser(String email, {BuildContext? context}) async {
    String currentUserId = await AuthController().getCurrentUserId();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/search?email=$email&currentUserId=$currentUserId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      else if (context != null && context.mounted) {
        final msg = jsonDecode(response.body)['message'] ?? "Lỗi tìm kiếm";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
      }
    } catch (e) { debugPrint("Lỗi tìm kiếm: $e"); }
    return null;
  }

  // 4. Tìm người dùng trên toàn hệ thống (Cập nhật UI)
  Future<void> searchGlobalUser(BuildContext context, String email) async {
    if (email.trim().isEmpty) return;
    var result = await searchUser(email.trim(), context: context); 
    if (result != null) {
      selectedFriend = {
        'id': result['id'], 'name': result['fullName'] ?? 'Người dùng',
        'avatarUrl': result['avatarUrl'] ?? '', 'coverUrl': result['coverUrl'] ?? '', 
        'bio': result['bio'] ?? 'Chưa có thông tin',
        'relationStatus': result['relationStatus'] ?? 'none', 'isFriend': result['isFriend'] ?? false
      };
      notifyListeners();
    }
  }

  // 5. Thêm / Hủy kết bạn
  Future<String> toggleFriendStatus(String friendId) async {
    String currentUserId = await AuthController().getCurrentUserId();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/add'), headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': currentUserId, 'friendId': friendId}),
      );
      if (response.statusCode == 200) {
        await loadFriends(); 
        return jsonDecode(response.body)['status']; 
      }
    } catch (e) { debugPrint("Lỗi kết bạn: $e"); }
    return "none"; 
  }

  Future<void> toggleFriendStatusFromPanel() async {
    if (selectedFriend == null) return;
    String newStatus = await toggleFriendStatus(selectedFriend!['id']);
    selectedFriend!['relationStatus'] = newStatus;
    selectedFriend!['isFriend'] = (newStatus == 'friend');
    notifyListeners();
  }
}