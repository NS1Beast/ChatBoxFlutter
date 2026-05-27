import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthFormType { login, register, forgotPassword }

class AuthController extends ChangeNotifier {
  AuthFormType currentForm = AuthFormType.login;
  
  bool isLoginPassVisible = false;
  bool isRegPassVisible = false;
  bool isRegConfirmPassVisible = false;

  final _storage = const FlutterSecureStorage();

  // Đổi cổng (Port) này cho khớp với Backend C# của ông đang chạy nhé
  final String _baseUrl = 'http://localhost:5000/api/auth'; 

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
  // GỌI API ĐĂNG NHẬP (CÓ CƠ CHẾ TEST NHANH)
  // ==========================================
  Future<bool> login(String email, String password) async {
    // 1. CƠ CHẾ TEST NHANH (BACKDOOR) DÀNH CHO DEV
    if (email == '1' && password == '1') {
      debugPrint('Đăng nhập bằng tài khoản DEV (1/1) thành công!');
      // Lưu một token giả để test các màn hình yêu cầu đăng nhập
      await _storage.write(key: 'jwt_token', value: 'dev_test_token_12345');
      return true;
    }

    // 2. LOGIC GỌI API THẬT NẾU KHÔNG PHẢI TÀI KHOẢN TEST
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
        
        // Lưu token vào vùng bảo mật
        await _storage.write(key: 'jwt_token', value: token);
        
        return true;
      } else {
        // Log lỗi hoặc lấy message từ Backend trả về
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
  // GỌI API QUÊN MẬT KHẨU (ĐÃ BỔ SUNG ĐỂ SỬA LỖI)
  // ==========================================
  Future<bool> resetPassword(String email) async {
    try {
      // Tạm thời giả lập thời gian chờ gọi API (1 giây)
      // Sau này ông viết API C# quên mật khẩu thì thay logic vào đây
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
  }
}