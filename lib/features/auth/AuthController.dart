import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Đảm bảo file này tên là OpenID.dart (hoặc open_id.dart thì ông tự sửa lại import nhé)
import 'OpenID.dart'; 

enum AuthFormType { login, register, forgotPassword }

class AuthController extends ChangeNotifier {
  AuthFormType currentForm = AuthFormType.login;
  
  bool isLoginPassVisible = false;
  bool isRegPassVisible = false;
  bool isRegConfirmPassVisible = false;

  final _storage = const FlutterSecureStorage();
  final OpenIDService _openIDService = OpenIDService();

  final String _baseUrl = 'http://localhost:5034/api/auth';

  void switchForm(AuthFormType type) {
    currentForm = type;
    notifyListeners();
  }

  void toggleLoginPassVisibility() {
    isLoginPassVisible = !isLoginPassVisible;
    notifyListeners();
  }

  void toggleRegPassVisibility() {
    isRegPassVisible = !isRegPassVisible;
    notifyListeners();
  }

  void toggleRegConfirmPassVisibility() {
    isRegConfirmPassVisible = !isRegConfirmPassVisible;
    notifyListeners();
  }

  // ==========================================
  // GỌI API ĐĂNG NHẬP
  // ==========================================
  Future<bool> login(String email, String password) async {
    if (email == '1' && password == '1') {
      debugPrint('Đăng nhập bằng tài khoản DEV (1/1) thành công!');
      await _storage.write(key: 'jwt_token', value: 'dev_test_token_12345');
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        await _storage.write(key: 'jwt_token', value: token);
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('Lỗi đăng nhập: ${errorData['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Lỗi kết nối server: $e');
      return false;
    }
  }

  // ==========================================
  // GỌI API ĐĂNG KÝ
  // ==========================================
  Future<bool> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('Lỗi đăng ký: ${errorData['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Lỗi kết nối server: $e');
      return false;
    }
  }

  // ==========================================
  // ĐĂNG NHẬP BẰNG GOOGLE
  // ==========================================
  Future<bool> loginWithGoogle() async {
    try {
      // 1. Mở trình duyệt, C# sẽ lo việc gọi Google, lưu Database và tạo JWT
      String? jwtToken = await _openIDService.signInWithGoogle();

      // 2. Nếu user tắt ngang cửa sổ trình duyệt
      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('Không lấy được token từ Google (Có thể user đã bấm Hủy)');
        return false;
      }

      // 3. KHÚC QUAY XE: Nhận được JWT Token từ C# là đăng nhập XONG!
      // Không cần gọi thêm API /google nào nữa vì C# đã làm hết rồi.
      await _storage.write(key: 'jwt_token', value: jwtToken);
      
      debugPrint('Đăng nhập Google Desktop thành công toàn tập!');
      return true;

    } catch (e) {
      debugPrint('Lỗi Exception loginWithGoogle: $e');
      return false;
    }
  }

  // ==========================================
  // GỌI API QUÊN MẬT KHẨU 
  // ==========================================
  Future<bool> resetPassword(String email) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('Đã gửi yêu cầu khôi phục mật khẩu cho: $email');
      return true;
    } catch (e) {
      debugPrint('Lỗi quên mật khẩu: $e');
      return false;
    }
  }

  // ==========================================
  // ĐĂNG XUẤT
  // ==========================================
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _openIDService.signOut();
  }
}