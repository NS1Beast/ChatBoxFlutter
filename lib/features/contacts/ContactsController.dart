// ignore_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  Future<Map<String, dynamic>?> searchUser(String email, {BuildContext? context}) async {
    String currentUserId = await AuthController().getCurrentUserId();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/search?email=$email&currentUserId=$currentUserId'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // 🎯 LẤY LỖI "TÌM CHÍNH MÌNH" TỪ BACKEND VÀ HIỂN THỊ SNACKBAR
        if (context != null && context.mounted) {
          final msg = jsonDecode(response.body)['message'] ?? "Lỗi tìm kiếm";
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
        }
      }
    } catch (e) {
      debugPrint("Lỗi tìm kiếm: $e");
    }
    return null;
  }

  // 3. Tìm người dùng trên toàn hệ thống (Cập nhật UI)
  Future<void> searchGlobalUser(BuildContext context, String email) async {
    if (email.trim().isEmpty) return;

    // 🎯 ĐÃ SỬA CHỖ NÀY: Truyền context vào để hàm searchUser có thể bung SnackBar lỗi
    var result = await searchUser(email.trim(), context: context); 
    
    if (result != null) {
      selectedFriend = {
        'id': result['id'],
        'name': result['fullName'] ?? 'Người dùng',
        'avatarUrl': result['avatarUrl'] ?? '',
        'coverUrl': result['coverUrl'] ?? '', 
        'bio': result['bio'] ?? 'Chưa có thông tin',
        // 🎯 Hứng thêm 2 trạng thái này để Giao diện biết đường xử lý
        'relationStatus': result['relationStatus'] ?? 'none',
        'isFriend': result['isFriend'] ?? false
      };
      notifyListeners();
    } else {
      // Vì lỗi "tìm chính mình" đã được show ở searchUser, nên đoạn dưới đây tui thêm check
      // để nếu không tìm thấy thật thì mới báo lỗi này, tránh báo 2 lỗi cùng lúc.
      if (context.mounted) {
        // Có thể ẩn dòng thông báo chung chung này đi nếu muốn, hoặc giữ nguyên cũng được.
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy người dùng này trên hệ thống!')));
      }
    }
  }

  // 4. Thêm / Hủy kết bạn
  Future<String> toggleFriendStatus(String friendId) async {
    String currentUserId = await AuthController().getCurrentUserId();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': currentUserId, 'friendId': friendId}),
      );
      
      if (response.statusCode == 200) {
        await loadFriends(); 
        return jsonDecode(response.body)['status']; 
      }
    } catch (e) {
      debugPrint("Lỗi kết bạn: $e");
    }
    return "none"; 
  }

  // Nút Kết bạn / Hủy bạn ở cột Phải màn hình
  Future<void> toggleFriendStatusFromPanel() async {
    if (selectedFriend == null) return;
    
    String newStatus = await toggleFriendStatus(selectedFriend!['id']);
    
    // Cập nhật lại dữ liệu để UI thay đổi theo
    selectedFriend!['relationStatus'] = newStatus;
    selectedFriend!['isFriend'] = (newStatus == 'friend');
    
    notifyListeners();
  }
}