// Đường dẫn: lib/features/settings/screens/SettingsScreen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/theme_controller.dart'; 
import '../settings/settings_controller.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _controller = SettingsController();

  // --- CÁC BIẾN TRẠNG THÁI GIẢ LẬP CHO UI MỚI (Sau này ông chuyển sang Controller nhé) ---
  bool _readReceipts = true;
  bool _enterToSend = true;
  bool _autoDownload = true;
  bool _appLock = false;

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ListenableBuilder(
          listenable: themeController,
          builder: (context, child) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Chọn màu chủ đạo',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 320,
                child: Wrap(
                  spacing: 16, runSpacing: 16,
                  children: _controller.extendedColors.map((color) {
                    bool isSelected = themeController.primaryColor.value == color.value;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => themeController.changePrimaryColor(color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                            boxShadow: [
                              if (isSelected) BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))
                            ],
                          ),
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // HEADER
              // ==========================================
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
                      'Cài đặt & Quản lý',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // NỘI DUNG CÀI ĐẶT
              // ==========================================
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // 1. KHU VỰC HỒ SƠ CAO CẤP
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    const CircleAvatar(radius: 40, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                                    Positioned(
                                      right: 0, bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: surfaceColor, width: 2)),
                                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Nam Pro Coder', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                                      const SizedBox(height: 4),
                                      Text('+84 987 654 321  •  @nam_pro', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text('Đang cày code xuyên màn đêm 💻', style: TextStyle(color: primaryColor, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.edit_rounded, size: 16),
                                  label: const Text('Chỉnh sửa'),
                                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 2. TÙY CHỈNH ĐOẠN CHAT
                          _buildSectionHeader('Cài đặt Chat'),
                          _buildSettingsGroup(surfaceColor, [
                            _buildNavigationTile(Icons.wallpaper_rounded, 'Hình nền đoạn chat', 'Tùy chỉnh ảnh nền cho các cuộc trò chuyện', onTap: () {}),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildNavigationTile(Icons.text_fields_rounded, 'Kích thước văn bản', 'Trung bình', onTap: () {}),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildSwitchTile(Icons.keyboard_return_rounded, 'Gửi bằng Enter', 'Nhấn phím Enter để gửi tin nhắn thay vì xuống dòng', _enterToSend, (val) => setState(() => _enterToSend = val)),
                          ]),
                          const SizedBox(height: 32),

                          // 3. QUYỀN RIÊNG TƯ & BẢO MẬT
                          _buildSectionHeader('Quyền riêng tư & Bảo mật'),
                          _buildSettingsGroup(surfaceColor, [
                            _buildSwitchTile(Icons.remove_red_eye_outlined, 'Hiển thị "Đã xem"', 'Người khác sẽ thấy khi bạn đã đọc tin nhắn của họ', _readReceipts, (val) => setState(() => _readReceipts = val)),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildNavigationTile(Icons.block_rounded, 'Danh sách chặn', 'Quản lý những người bạn đã chặn', onTap: () {}),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildSwitchTile(Icons.lock_outline_rounded, 'Khóa ứng dụng', 'Yêu cầu mật khẩu khi mở ứng dụng', _appLock, (val) => setState(() => _appLock = val)),
                          ]),
                          const SizedBox(height: 32),

                          // 4. DỮ LIỆU & LƯU TRỮ
                          _buildSectionHeader('Dữ liệu & Lưu trữ'),
                          _buildSettingsGroup(surfaceColor, [
                            _buildNavigationTile(Icons.data_usage_rounded, 'Mức sử dụng dung lượng', 'Chiếm 2.4 GB trên máy tính', onTap: () {}),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildSwitchTile(Icons.download_for_offline_rounded, 'Tự động tải phương tiện', 'Tự động lưu ảnh và file đính kèm vào máy tính', _autoDownload, (val) => setState(() => _autoDownload = val)),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildNavigationTile(Icons.cleaning_services_rounded, 'Xóa bộ nhớ đệm (Cache)', 'Giải phóng dung lượng rác', iconColor: Colors.orange, onTap: () {}),
                          ]),
                          const SizedBox(height: 32),

                          // 5. GIAO DIỆN & HIỂN THỊ (Cũ)
                          _buildSectionHeader('Giao diện & Hiển thị'),
                          _buildSettingsGroup(surfaceColor, [
                            _buildSwitchTile(Icons.dark_mode_outlined, 'Chế độ tối (Dark Mode)', 'Sử dụng giao diện nền đen', themeController.isDarkMode, (val) => themeController.toggleDarkMode(val)),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            
                            // Vùng chọn màu chủ đạo
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Row(
                                children: [
                                  _buildIconContainer(Icons.color_lens_outlined),
                                  const SizedBox(width: 16),
                                  Expanded(child: Text('Màu chủ đạo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor))),
                                  Row(
                                    children: [
                                      ..._controller.colorPresets.map((color) {
                                        bool isSelected = themeController.primaryColor.value == color.value;
                                        return MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () => themeController.changePrimaryColor(color),
                                            child: Container(
                                              margin: const EdgeInsets.only(left: 8), width: 28, height: 28,
                                              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isSelected ? Border.all(color: textColor, width: 2) : null),
                                            ),
                                          ),
                                        );
                                      }),
                                      
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: _showColorPicker,
                                          child: Container(
                                            margin: const EdgeInsets.only(left: 12), width: 28, height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red]),
                                              border: !_controller.colorPresets.contains(themeController.primaryColor) ? Border.all(color: textColor, width: 2) : null,
                                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ]),
                          const SizedBox(height: 32),

                          // 6. THÔNG BÁO & ÂM THANH (Cũ)
                          _buildSectionHeader('Thông báo & Âm thanh'),
                          _buildSettingsGroup(surfaceColor, [
                            _buildSwitchTile(Icons.notifications_active_outlined, 'Cho phép thông báo', 'Hiển thị thông báo khi có tin nhắn mới', _controller.notifications, (val) => _controller.toggleNotifications(val)),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildSwitchTile(Icons.volume_up_outlined, 'Âm thanh', 'Phát âm thanh khi gửi và nhận tin', _controller.sound, (val) => _controller.toggleSound(val)),
                          ]),
                          const SizedBox(height: 32),

                          // 7. TÀI KHOẢN
                          _buildSectionHeader('Tài khoản'),
                          _buildSettingsGroup(surfaceColor, [
                            _buildNavigationTile(Icons.shield_outlined, 'Đổi mật khẩu', 'Cập nhật lại mật khẩu đăng nhập', onTap: () {}),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildNavigationTile(Icons.logout_rounded, 'Đăng xuất', 'Thoát tài khoản khỏi thiết bị này', iconColor: Colors.red, textColor: Colors.red, onTap: () {}),
                          ]),
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

  // --- CÁC HÀM XÂY DỰNG COMPONENT ---

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

  // Chức năng dạng Switch Tắt/Bật
  Widget _buildSwitchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: _buildIconContainer(icon),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      hoverColor: Colors.transparent,
      trailing: Switch(value: value, onChanged: onChanged, activeColor: Theme.of(context).colorScheme.primary),
    );
  }

  // Thêm mới: Chức năng dạng Navigation (Chuyển trang/Mở Dialog)
  Widget _buildNavigationTile(IconData icon, String title, String subtitle, {Color? iconColor, Color? textColor, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: _buildIconContainer(icon, iconColor: iconColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor ?? Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      hoverColor: (iconColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }

  Widget _buildIconContainer(IconData icon, {Color? iconColor}) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 22),
    );
  }
}