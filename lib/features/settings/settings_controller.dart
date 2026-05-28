// Đường dẫn: lib/features/settings/controllers/settings_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  String _currentUserId = "guest"; 

  // --- STATE (Trạng thái) ---
  bool notifications = true;
  bool sound = true;
  bool autoDownload = true;
  bool readReceipts = true;
  bool enterToSend = true;
  bool appLock = false;
  
  // Thêm 2 biến để hứng giao diện từ Local Storage
  int primaryColorValue = 0xFF2979FF; // Mặc định xanh dương
  bool isDarkMode = false; 

  // --- DATA (Dữ liệu) ---
  final List<Color> colorPresets = [
    const Color(0xFF8470FF), // Tím
    const Color(0xFF00C853), // Xanh lá
    const Color(0xFF2979FF), // Xanh dương
  ];

  final List<Color> extendedColors = [
    const Color(0xFF8470FF), Colors.red, Colors.pink, Colors.purple,
    Colors.deepPurple, Colors.indigo, Colors.blue, Colors.lightBlue,
    Colors.cyan, Colors.teal, Colors.green, Colors.lightGreen,
    Colors.lime, Colors.yellow, Colors.amber, Colors.orange,
    Colors.deepOrange, Colors.brown, Colors.grey, Colors.blueGrey,
    const Color(0xFFE91E63), const Color(0xFF00C853), const Color(0xFF2979FF), const Color(0xFFFF3D00)
  ];

  // ==========================================
  // HÀM KHỞI TẠO DỮ LIỆU KHI ĐĂNG NHẬP
  // ==========================================
  Future<void> loadSettingsForUser(String userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();

    notifications = prefs.getBool('${_currentUserId}_notifications') ?? true;
    sound = prefs.getBool('${_currentUserId}_sound') ?? true;
    autoDownload = prefs.getBool('${_currentUserId}_autoDownload') ?? true;
    readReceipts = prefs.getBool('${_currentUserId}_readReceipts') ?? true;
    enterToSend = prefs.getBool('${_currentUserId}_enterToSend') ?? true;
    appLock = prefs.getBool('${_currentUserId}_appLock') ?? false;

    // Load thêm Giao diện của riêng user này
    primaryColorValue = prefs.getInt('${_currentUserId}_primaryColor') ?? 0xFF2979FF;
    isDarkMode = prefs.getBool('${_currentUserId}_isDarkMode') ?? false;

    notifyListeners(); 
  }

  // ==========================================
  // HÀM LƯU DỮ LIỆU
  // ==========================================
  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_currentUserId}_$key', value);
  }

  // Hàm riêng để lưu hệ mã Màu (dạng Số int)
  Future<void> savePrimaryColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_currentUserId}_primaryColor', color.value);
  }

  Future<void> saveDarkMode(bool value) async {
    await _saveSetting('isDarkMode', value);
  }

  // --- LOGIC FUNCTIONS ---
  void toggleNotifications(bool value) {
    notifications = value;
    _saveSetting('notifications', value);
    notifyListeners();
  }

  void toggleSound(bool value) {
    sound = value;
    _saveSetting('sound', value);
    notifyListeners();
  }

  void toggleAutoDownload(bool value) {
    autoDownload = value;
    _saveSetting('autoDownload', value);
    notifyListeners();
  }

  void toggleReadReceipts(bool value) {
    readReceipts = value;
    _saveSetting('readReceipts', value);
    notifyListeners();
  }

  void toggleEnterToSend(bool value) {
    enterToSend = value;
    _saveSetting('enterToSend', value);
    notifyListeners();
  }

  void toggleAppLock(bool value) {
    appLock = value;
    _saveSetting('appLock', value);
    notifyListeners();
  }
}