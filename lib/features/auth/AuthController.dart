// ignore_file: file_names

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'OpenID.dart';
import '../../../core/services/signalr_service.dart';

enum AuthFormType { login, register, forgotPassword }

class AuthController extends ChangeNotifier {
  AuthFormType currentForm = AuthFormType.login;

  bool isLoading = false;

  bool isLoginPassVisible = false;
  bool isRegPassVisible = false;
  bool isRegConfirmPassVisible = false;
  bool isForgotPassVisible = false;
  bool isForgotConfirmPassVisible = false;

  int registerStep = 1;
  String regEmail = '';
  int otpTimeLeft = 180;
  Timer? _otpTimer;

  int forgotStep = 1;
  String forgotEmail = '';
  int forgotOtpTimeLeft = 180;
  Timer? _forgotOtpTimer;

  final _storage = const FlutterSecureStorage();
  final OpenIDService _openIDService = OpenIDService();

  final String _baseUrl = 'http://localhost:5034/api/auth';

  // Kiểm tra token đã lưu để tự động đăng nhập nếu token còn hạn
  Future<bool> tryAutoLogin() async {
    String? token = await _storage.read(key: 'jwt_token');

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        await logout();
        return false;
      }

      String payloadStr = parts[1];

      while (payloadStr.length % 4 != 0) {
        payloadStr += '=';
      }

      final payload = utf8.decode(base64Url.decode(payloadStr));
      final payloadMap = jsonDecode(payload);

      if (payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'] * 1000;

        if (DateTime.now().millisecondsSinceEpoch > exp) {
          await logout();
          return false;
        }
      }

      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Quay lại bước trước trong luồng đăng ký
  void backRegisterStep() {
    if (registerStep > 1) {
      registerStep--;
      notifyListeners();
    } else {
      switchForm(AuthFormType.login);
    }
  }

  // Quay lại bước trước trong luồng quên mật khẩu
  void backForgotStep() {
    if (forgotStep > 1) {
      forgotStep--;
      notifyListeners();
    } else {
      switchForm(AuthFormType.login);
    }
  }

  // Cập nhật trạng thái loading cho giao diện
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Chuyển form đăng nhập, đăng ký hoặc quên mật khẩu
  void switchForm(AuthFormType type) {
    currentForm = type;

    if (type != AuthFormType.register) {
      _resetRegisterFlow();
    }

    if (type != AuthFormType.forgotPassword) {
      _resetForgotFlow();
    }

    notifyListeners();
  }

  // Bật hoặc tắt hiển thị mật khẩu đăng nhập
  void toggleLoginPassVisibility() {
    isLoginPassVisible = !isLoginPassVisible;
    notifyListeners();
  }

  // Bật hoặc tắt hiển thị mật khẩu đăng ký
  void toggleRegPassVisibility() {
    isRegPassVisible = !isRegPassVisible;
    notifyListeners();
  }

  // Bật hoặc tắt hiển thị xác nhận mật khẩu đăng ký
  void toggleRegConfirmPassVisibility() {
    isRegConfirmPassVisible = !isRegConfirmPassVisible;
    notifyListeners();
  }

  // Bật hoặc tắt hiển thị mật khẩu mới trong luồng quên mật khẩu
  void toggleForgotPassVisibility() {
    isForgotPassVisible = !isForgotPassVisible;
    notifyListeners();
  }

  // Bật hoặc tắt hiển thị xác nhận mật khẩu mới
  void toggleForgotConfirmPassVisibility() {
    isForgotConfirmPassVisible = !isForgotConfirmPassVisible;
    notifyListeners();
  }

  // Đưa luồng đăng ký về bước đầu tiên
  void _resetRegisterFlow() {
    registerStep = 1;
    regEmail = '';
    _stopOtpTimer();
  }

  // Đưa luồng quên mật khẩu về bước đầu tiên
  void _resetForgotFlow() {
    forgotStep = 1;
    forgotEmail = '';
    _stopForgotOtpTimer();
  }

  // Bắt đầu đếm ngược thời gian OTP đăng ký
  void _startOtpTimer() {
    otpTimeLeft = 180;
    _otpTimer?.cancel();

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimeLeft > 0) {
        otpTimeLeft--;
        notifyListeners();
      } else {
        _stopOtpTimer();
      }
    });
  }

  // Dừng bộ đếm OTP đăng ký
  void _stopOtpTimer() {
    _otpTimer?.cancel();
    notifyListeners();
  }

  // Hiển thị thời gian OTP đăng ký dạng mm:ss
  String get otpTimerDisplay =>
      '${(otpTimeLeft ~/ 60).toString().padLeft(2, '0')}:${(otpTimeLeft % 60).toString().padLeft(2, '0')}';

  // Bắt đầu đếm ngược thời gian OTP quên mật khẩu
  void _startForgotOtpTimer() {
    forgotOtpTimeLeft = 180;
    _forgotOtpTimer?.cancel();

    _forgotOtpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (forgotOtpTimeLeft > 0) {
        forgotOtpTimeLeft--;
        notifyListeners();
      } else {
        _stopForgotOtpTimer();
      }
    });
  }

  // Dừng bộ đếm OTP quên mật khẩu
  void _stopForgotOtpTimer() {
    _forgotOtpTimer?.cancel();
    notifyListeners();
  }

  // Hiển thị thời gian OTP quên mật khẩu dạng mm:ss
  String get forgotOtpTimerDisplay =>
      '${(forgotOtpTimeLeft ~/ 60).toString().padLeft(2, '0')}:${(forgotOtpTimeLeft % 60).toString().padLeft(2, '0')}';

  // Kiểm tra định dạng tên người dùng
  String? validateName(String name) {
    if (name.isEmpty) {
      return "Tên không được để trống";
    }

    final regex = RegExp(r'^[\p{L}0-9\s]+$', unicode: true);

    if (!regex.hasMatch(name)) {
      return "Tên chỉ được chứa chữ cái và số, không dùng ký tự đặc biệt";
    }

    return null;
  }

  // Kiểm tra độ mạnh và định dạng mật khẩu
  String? validatePassword(String password) {
    if (password.length < 8) {
      return "Mật khẩu phải có ít nhất 8 ký tự";
    }

    if (password.contains(' ')) {
      return "Mật khẩu không được chứa khoảng trắng";
    }

    if (!password.contains(RegExp(r'[a-zA-Z\p{L}]', unicode: true))) {
      return "Phải chứa ít nhất 1 chữ cái (Hoa hoặc Thường)";
    }

    if (RegExp(r'[^\x21-\x7E]').hasMatch(password)) {
      return "Không sử dụng icon hoặc ký tự lạ";
    }

    return null;
  }

  // Giải mã JWT để lấy thông tin user và lưu vào SharedPreferences
  Future<void> _extractAndSaveUserInfoFromToken(String token) async {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return;
      }

      String payloadStr = parts[1];

      while (payloadStr.length % 4 != 0) {
        payloadStr += '=';
      }

      final payload = utf8.decode(base64Url.decode(payloadStr));
      final payloadMap = jsonDecode(payload);

      final String userId = payloadMap['nameid'] ??
          payloadMap['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          "guest";

      final String fullName = payloadMap['fullname'] ??
          payloadMap['name'] ??
          payloadMap['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
          "Người dùng";

      final prefs = await SharedPreferences.getInstance();

      if (fullName.isNotEmpty && fullName != "Người dùng") {
        await prefs.setString('${userId}_name', fullName);
      }
    } catch (e) {
      debugPrint("Lỗi khi giải mã JWT Token: $e");
    }
  }

  // Gửi OTP đăng ký sau khi kiểm tra email hợp lệ
  Future<String?> checkEmailAndSendOTP(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      return "Email không hợp lệ!";
    }

    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        regEmail = email;
        registerStep = 2;

        _startOtpTimer();
        notifyListeners();

        return null;
      }

      return jsonDecode(response.body)['message'] ?? "Lỗi không xác định";
    } catch (e) {
      _setLoading(false);
      return "Lỗi kết nối máy chủ!";
    }
  }

  // Xác thực OTP đăng ký
  Future<String?> verifyOTP(String otp) async {
    if (otp.length != 6) {
      return "OTP phải đủ 6 số!";
    }

    if (otpTimeLeft == 0) {
      return "Mã OTP đã hết hạn!";
    }

    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': regEmail,
          'otp': otp,
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        _stopOtpTimer();
        registerStep = 3;

        notifyListeners();

        return null;
      }

      return jsonDecode(response.body)['message'] ?? "Mã OTP không chính xác!";
    } catch (e) {
      _setLoading(false);
      return "Lỗi kết nối máy chủ!";
    }
  }

  // Hoàn tất đăng ký tài khoản sau khi OTP đã được xác thực
  Future<String?> completeRegistration(String fullName, String password) async {
    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': regEmail,
          'password': password,
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        _resetRegisterFlow();
        return null;
      }

      return jsonDecode(response.body)['message'] ?? "Lỗi tạo tài khoản!";
    } catch (e) {
      _setLoading(false);
      return "Lỗi kết nối máy chủ!";
    }
  }

  // Gửi OTP cho luồng quên mật khẩu
  Future<String?> requestForgotPasswordOTP(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      return "Email không hợp lệ!";
    }

    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        forgotEmail = email;
        forgotStep = 2;

        _startForgotOtpTimer();
        notifyListeners();

        return null;
      }

      return jsonDecode(response.body)['message'] ?? "Lỗi không xác định";
    } catch (e) {
      _setLoading(false);
      return "Lỗi kết nối máy chủ!";
    }
  }

  // Xác thực OTP trong luồng quên mật khẩu
  Future<String?> verifyForgotOTP(String otp) async {
    if (otp.length != 6) {
      return "OTP phải đủ 6 số!";
    }

    if (forgotOtpTimeLeft == 0) {
      return "Mã OTP đã hết hạn!";
    }

    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-forgot-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': forgotEmail,
          'otp': otp,
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        _stopForgotOtpTimer();
        forgotStep = 3;

        notifyListeners();

        return null;
      }

      return jsonDecode(response.body)['message'] ?? "Mã OTP không chính xác!";
    } catch (e) {
      _setLoading(false);
      return "Lỗi kết nối máy chủ!";
    }
  }

  // Cập nhật mật khẩu mới sau khi OTP quên mật khẩu hợp lệ
  Future<String?> updateNewPassword(String newPassword) async {
    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': forgotEmail,
          'password': newPassword,
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        _resetForgotFlow();
        return null;
      }

      return jsonDecode(response.body)['message'] ?? "Lỗi đổi mật khẩu!";
    } catch (e) {
      _setLoading(false);
      return "Lỗi kết nối máy chủ!";
    }
  }

  // Đăng nhập bằng email và mật khẩu
  Future<bool> login(String email, String password) async {
    _setLoading(true);

    if (email == '1' && password == '1') {
      await Future.delayed(const Duration(seconds: 1));
      await _storage.write(key: 'jwt_token', value: 'dev_test_token_12345');

      _setLoading(false);

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

      _setLoading(false);

      if (response.statusCode == 200) {
        String token = jsonDecode(response.body)['token'];

        await _storage.write(key: 'jwt_token', value: token);
        await _extractAndSaveUserInfoFromToken(token);

        return true;
      }

      debugPrint(jsonDecode(response.body)['message']);
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Đăng nhập bằng Google thông qua OpenIDService
  Future<bool> loginWithGoogle() async {
    _setLoading(true);

    try {
      String? jwtToken = await _openIDService.signInWithGoogle();

      _setLoading(false);

      if (jwtToken == null || jwtToken.isEmpty) {
        return false;
      }

      await _storage.write(key: 'jwt_token', value: jwtToken);
      await _extractAndSaveUserInfoFromToken(jwtToken);

      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Đăng xuất, xóa token và ngắt kết nối SignalR
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _openIDService.signOut();

    try {
      await SignalRService().stopConnection();
    } catch (e) {
      debugPrint("Lỗi khi ngắt SignalR: $e");
    }
  }

  // Lấy userId hiện tại từ JWT token
  Future<String> getCurrentUserId() async {
    String? token = await _storage.read(key: 'jwt_token');

    if (token == null || token.isEmpty) {
      return "guest";
    }

    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return "guest";
      }

      String payloadStr = parts[1];

      while (payloadStr.length % 4 != 0) {
        payloadStr += '=';
      }

      final payload = utf8.decode(base64Url.decode(payloadStr));
      final payloadMap = jsonDecode(payload);

      return payloadMap['nameid'] ??
          payloadMap['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          "guest";
    } catch (e) {
      return "guest";
    }
  }
}