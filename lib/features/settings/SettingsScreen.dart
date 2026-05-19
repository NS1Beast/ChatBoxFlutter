// Đường dẫn: lib/features/settings/screens/SettingsScreen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/theme_controller.dart'; 
// Import "Backend" của Settings vào
import '../settings/settings_controller.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Khởi tạo Backend Controller cho màn hình này
  final SettingsController _controller = SettingsController();

  // Hàm hiển thị Popup (Giữ ở Frontend vì liên quan trực tiếp đến việc vẽ UI)
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ListenableBuilder(
          listenable: themeController,
          builder: (context, child) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Chọn màu chủ đạo',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 320,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  // Lấy danh sách màu từ Controller
                  children: _controller.extendedColors.map((color) {
                    bool isSelected = themeController.primaryColor.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        themeController.changePrimaryColor(color);
                      },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected 
                            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) 
                            : null,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Đóng', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    // Dùng ListenableBuilder để lắng nghe sự thay đổi từ Controller
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, size: 28, color: textColor),
                    const SizedBox(width: 16),
                    Text(
                      'Cài đặt hệ thống',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ),

              // Nội dung Cài đặt
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Giao diện & Hiển thị'),
                          _buildSettingsGroup(
                            surfaceColor,
                            [
                              _buildSwitchTile(
                                Icons.dark_mode_outlined, 
                                'Chế độ tối (Dark Mode)', 
                                'Sử dụng giao diện nền đen', 
                                themeController.isDarkMode,
                                (val) => themeController.toggleDarkMode(val),
                              ),
                              const Divider(height: 1, indent: 56, endIndent: 16),
                              
                              // Vùng chọn màu chủ đạo
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    _buildIconContainer(Icons.color_lens_outlined),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text('Màu chủ đạo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
                                    ),
                                    Row(
                                      children: [
                                        // Gọi danh sách màu rút gọn từ Controller
                                        ..._controller.colorPresets.map((color) {
                                          bool isSelected = themeController.primaryColor.value == color.value;
                                          return GestureDetector(
                                            onTap: () => themeController.changePrimaryColor(color),
                                            child: Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              width: 28, height: 28,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                                border: isSelected ? Border.all(color: textColor, width: 2) : null,
                                              ),
                                            ),
                                          );
                                        }),
                                        
                                        // Ô bảng màu
                                        GestureDetector(
                                          onTap: _showColorPicker,
                                          child: Container(
                                            margin: const EdgeInsets.only(left: 12),
                                            width: 28, height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const SweepGradient(
                                                colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red],
                                              ),
                                              border: !_controller.colorPresets.contains(themeController.primaryColor)
                                                  ? Border.all(color: textColor, width: 2) 
                                                  : null,
                                              boxShadow: [
                                                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
                                              ]
                                            ),
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                          _buildSectionHeader('Thông báo & Âm thanh'),
                          _buildSettingsGroup(
                            surfaceColor,
                            [
                              // Trỏ State qua _controller thay vì dùng biến trực tiếp
                              _buildSwitchTile(
                                Icons.notifications_active_outlined, 'Cho phép thông báo', 'Hiển thị thông báo khi có tin nhắn mới', 
                                _controller.notifications, (val) => _controller.toggleNotifications(val)
                              ),
                              const Divider(height: 1, indent: 56, endIndent: 16),
                              _buildSwitchTile(
                                Icons.volume_up_outlined, 'Âm thanh', 'Phát âm thanh khi gửi và nhận tin', 
                                _controller.sound, (val) => _controller.toggleSound(val)
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsGroup(Color surfaceColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: _buildIconContainer(icon),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 22),
    );
  }
}