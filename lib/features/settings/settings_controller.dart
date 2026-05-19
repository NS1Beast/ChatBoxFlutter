// Đường dẫn: lib/features/settings/controllers/settings_controller.dart
import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  // --- STATE (Trạng thái) ---
  bool notifications = true;
  bool sound = true;
  bool autoDownload = true;
  bool readReceipts = true;

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

  // --- LOGIC FUNCTIONS (Hàm xử lý) ---
  void toggleNotifications(bool value) {
    notifications = value;
    notifyListeners(); // Thông báo cho Frontend cập nhật UI
  }

  void toggleSound(bool value) {
    sound = value;
    notifyListeners();
  }

  void toggleAutoDownload(bool value) {
    autoDownload = value;
    notifyListeners();
  }

  void toggleReadReceipts(bool value) {
    readReceipts = value;
    notifyListeners();
  }
}