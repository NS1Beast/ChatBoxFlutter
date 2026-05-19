import 'package:flutter/material.dart';

// Đưa Enum ra đây để quản lý trạng thái form
enum AuthFormType { login, register, forgotPassword }

class AuthController extends ChangeNotifier {
  // --- STATE (Trạng thái giao diện) ---
  AuthFormType currentForm = AuthFormType.login;
  bool isLoginPassVisible = false;
  bool isRegPassVisible = false;
  bool isRegConfirmPassVisible = false;

  // --- LOGIC FUNCTIONS (Hàm điều khiển giao diện) ---
  void switchForm(AuthFormType formType) {
    currentForm = formType;
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

  // --- API CALLS (Hàm xử lý dữ liệu giả lập) ---
  
  // Trả về true nếu đăng nhập thành công
  Future<bool> login(String email, String password) async {
    // Tương lai bạn sẽ gọi API Supabase ở đây: await SupabaseManager.Client.Auth.SignIn(...)
    await Future.delayed(const Duration(milliseconds: 500)); // Giả lập load mạng
    return true; 
  }

  Future<bool> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}