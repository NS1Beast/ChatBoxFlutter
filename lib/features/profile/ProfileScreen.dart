import 'package:flutter/material.dart';
import 'ProfileController.dart'; // Gọi Controller cùng cấp thư mục

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Khởi tạo Controller chứa dữ liệu Backend
  final ProfileController _controller = ProfileController();

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    // Dùng ListenableBuilder để giao diện tự động vẽ lại nếu Controller có thay đổi
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Hồ sơ của bạn',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ==========================================
                      // 1. KHU VỰC ẢNH BÌA & AVATAR
                      // ==========================================
                      SizedBox(
                        height: 220,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Ảnh bìa
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: _controller.coverImageUrl == 'default'
                                    ? const Icon(Icons.auto_awesome, color: Colors.white24, size: 80)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Image.network(_controller.coverImageUrl, fit: BoxFit.cover),
                                      ),
                              ),
                            ),
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundImage: NetworkImage(_controller.avatarUrl),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ==========================================
                      // 2. THÔNG TIN CƠ BẢN (Lấy từ Controller)
                      // ==========================================
                      Text(
                        _controller.fullName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _controller.headline,
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _controller.bio,
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Nút hành động (Gọi hàm từ Controller)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _controller.editProfile,
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Chỉnh sửa', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _controller.shareProfile,
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ==========================================
                      // 3. THẺ THÔNG TIN CHI TIẾT
                      // ==========================================
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(context, Icons.email_outlined, 'Email', _controller.email, subtitleColor, textColor),
                            const Divider(height: 1, indent: 56, endIndent: 24),
                            _buildInfoTile(context, Icons.phone_outlined, 'Số điện thoại', _controller.phoneNumber, subtitleColor, textColor),
                            const Divider(height: 1, indent: 56, endIndent: 24),
                            _buildInfoTile(context, Icons.location_on_outlined, 'Vị trí', _controller.location, subtitleColor, textColor),
                            const Divider(height: 1, indent: 56, endIndent: 24),
                            _buildInfoTile(context, Icons.calendar_today_outlined, 'Ngày tham gia', _controller.joinDate, subtitleColor, textColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // 4. THẺ CÀI ĐẶT TÀI KHOẢN
                      // ==========================================
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              context, Icons.notifications_none_rounded, 'Thông báo Push', textColor, subtitleColor,
                              hasSwitch: true, switchValue: _controller.pushNotifications,
                              onSwitchChanged: (val) => _controller.toggleNotifications(val),
                            ),
                            const Divider(height: 1, indent: 56, endIndent: 24),
                            _buildSettingsTile(
                              context, Icons.lock_outline_rounded, 'Tài khoản riêng tư', textColor, subtitleColor,
                              hasSwitch: true, switchValue: _controller.privateProfile,
                              onSwitchChanged: (val) => _controller.togglePrivacy(val),
                            ),
                            const Divider(height: 1, indent: 56, endIndent: 24),
                            _buildSettingsTile(
                              context, Icons.language_rounded, 'Ngôn ngữ', textColor, subtitleColor,
                              hasSwitch: false, trailingText: _controller.currentLanguage,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Nút Đăng xuất
                      TextButton.icon(
                        onPressed: _controller.logout,
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        label: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  // Widget hỗ trợ hiển thị từng dòng thông tin
  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle, Color titleColor, Color subtitleColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      ),
      title: Text(title, style: TextStyle(color: titleColor, fontSize: 13)),
      subtitle: Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }

  // Widget hỗ trợ hiển thị cài đặt (có truyền thêm các callback cho Switch)
  Widget _buildSettingsTile(
    BuildContext context, IconData icon, String title, Color textColor, Color subtitleColor, 
    {required bool hasSwitch, bool switchValue = false, ValueChanged<bool>? onSwitchChanged, String? trailingText}
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: textColor, size: 22),
      ),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: hasSwitch
          ? Switch(
              value: switchValue,
              onChanged: onSwitchChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingText != null)
                  Text(trailingText, style: TextStyle(color: subtitleColor, fontSize: 14)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: subtitleColor),
              ],
            ),
      onTap: () {},
    );
  }
}