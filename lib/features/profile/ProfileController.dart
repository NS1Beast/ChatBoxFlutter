import 'package:flutter/material.dart';

class ProfileController extends ChangeNotifier {
  // --- MÔ PHỎNG DỮ LIỆU TỪ BACKEND / DATABASE ---
  
  // Thông tin cơ bản
  String coverImageUrl = 'default'; // Sẽ dùng Icon pattern nếu là 'default'
  String avatarUrl = 'https://i.pravatar.cc/150?img=11';
  String fullName = 'Nam';
  String headline = 'Senior IT Student - AI Enthusiast 🚀';
  String bio = 'Đam mê C#, Python & Flutter | Thích Gym & Gaming';
  
  // Chi tiết liên hệ & Hệ thống
  String email = 'nam.dev@prochat.com';
  String phoneNumber = '+84 123 456 789';
  String location = 'Hồ Chí Minh, Việt Nam';
  String joinDate = 'Tháng 5, 2026';

  // --- TRẠNG THÁI CÀI ĐẶT RIÊNG CỦA HỒ SƠ ---
  bool pushNotifications = true;
  bool privateProfile = false;
  String currentLanguage = 'Tiếng Việt';

  // --- CÁC HÀM XỬ LÝ (LOGIC) ---

  // Hàm mô phỏng việc bấm nút Chỉnh sửa
  void editProfile() {
    // Thực tế sẽ mở Dialog hoặc Navigate sang trang Edit
    print('Đang mở form chỉnh sửa hồ sơ cho $fullName');
  }

  // Hàm mô phỏng việc chia sẻ hồ sơ
  void shareProfile() {
    print('Chia sẻ hồ sơ của $fullName (Email: $email)');
  }

  // Hàm chuyển đổi cài đặt thông báo
  void toggleNotifications(bool value) {
    pushNotifications = value;
    notifyListeners();
  }

  // Hàm chuyển đổi quyền riêng tư
  void togglePrivacy(bool value) {
    privateProfile = value;
    notifyListeners();
  }

  // Hàm đăng xuất
  void logout() {
    print('Thực hiện đăng xuất tài khoản: $email');
    // Ở đây sẽ gọi Supabase Auth signout sau này
  }
}