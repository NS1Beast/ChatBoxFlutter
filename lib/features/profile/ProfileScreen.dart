// Đường dẫn: lib/features/profile/ProfileScreen.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'ProfileController.dart'; 
// Nhớ import AuthController để lấy ID nhé
import '../../features/auth/AuthController.dart'; // Đổi đường dẫn cho khớp máy ông nếu cần

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();
  
  // 🎯 Thêm biến này để lưu ID của user, lát nữa truyền vào các hàm cắt ảnh/lưu chữ
  String _currentUserId = "guest"; 

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // 1. Lấy ID của ông đang đăng nhập và gán vào biến toàn cục của class
    _currentUserId = await AuthController().getCurrentUserId();
    // 2. Chọc lên Backend lấy Avatar Google và Tên về đắp vào giao diện
    await _controller.loadUserProfile(_currentUserId);
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _controller.fullName);
    final headlineCtrl = TextEditingController(text: _controller.headline);
    final bioCtrl = TextEditingController(text: _controller.bio);
    final phoneCtrl = TextEditingController(text: _controller.phoneNumber);
    final locationCtrl = TextEditingController(text: _controller.location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameCtrl, 'Họ và tên', Icons.person),
                const SizedBox(height: 16),
                _buildTextField(headlineCtrl, 'Tiêu đề (Headline)', Icons.work_outline),
                const SizedBox(height: 16),
                _buildTextField(bioCtrl, 'Giới thiệu bản thân (Bio)', Icons.info_outline, maxLines: 3),
                const SizedBox(height: 16),
                _buildTextField(phoneCtrl, 'Số điện thoại', Icons.phone),
                const SizedBox(height: 16),
                _buildTextField(locationCtrl, 'Vị trí', Icons.location_on_outlined),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              // 🎯 Đã thêm tham số userId vào đây
              _controller.updateProfileText(
                userId: _currentUserId, 
                newName: nameCtrl.text, 
                newHeadline: headlineCtrl.text, 
                newBio: bioCtrl.text, 
                newPhone: phoneCtrl.text, 
                newLocation: locationCtrl.text
              );
              Navigator.pop(context);
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
    );
  }

  ImageProvider _getAvatarImage() {
    if (_controller.localAvatarBytes != null) {
      return MemoryImage(_controller.localAvatarBytes!); 
    } else if (_controller.avatarUrl.isNotEmpty) {
      return NetworkImage(_controller.avatarUrl); 
    } else {
      return MemoryImage(Uint8List(0)); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          appBar: AppBar(
            backgroundColor: Colors.transparent, elevation: 0,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
            title: Text('Hồ sơ của bạn', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
                      // --- KHU VỰC ẢNH BÌA & AVATAR ---
                      SizedBox(
                        height: 220,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Stack(
                                children: [
                                  Container(
                                    height: 160, width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                                      image: _controller.localCoverBytes != null 
                                          ? DecorationImage(image: MemoryImage(_controller.localCoverBytes!), fit: BoxFit.cover)
                                          : (_controller.coverImageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(_controller.coverImageUrl), fit: BoxFit.cover) : null)
                                    ),
                                    child: (_controller.localCoverBytes == null && _controller.coverImageUrl.isEmpty) ? const Icon(Icons.auto_awesome, color: Colors.white24, size: 80) : null,
                                  ),
                                  Positioned(
                                    top: 16, right: 16,
                                    child: IconButton.filled(
                                      // 🎯 Đã truyền thêm _currentUserId
                                      onPressed: () => _controller.pickAndCropCover(context, _currentUserId),
                                      icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
                                  child: CircleAvatar(
                                    radius: 56, backgroundColor: Colors.grey[300],
                                    backgroundImage: _getAvatarImage(),
                                    child: (_controller.localAvatarBytes == null && _controller.avatarUrl.isEmpty) ? Icon(Icons.person_rounded, size: 60, color: Colors.grey[600]) : null, 
                                  ),
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: GestureDetector(
                                    // 🎯 Đã truyền thêm _currentUserId
                                    onTap: () => _controller.pickAndCropAvatar(context, _currentUserId),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest, width: 3)),
                                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- THÔNG TIN CƠ BẢN ---
                      Text(_controller.fullName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 8),
                      Text(_controller.headline, style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(_controller.bio, style: TextStyle(color: subtitleColor, fontSize: 14), textAlign: TextAlign.center),
                      const SizedBox(height: 24),

                      // --- NÚT ACTION CHỈNH SỬA ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _showEditProfileDialog,
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Chỉnh sửa', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _controller.shareProfile,
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // --- CÁC NỘI DUNG DƯỚI GIỮ NGUYÊN NHƯ CŨ ---
                      Container(
                        decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
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

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle, Color titleColor, Color subtitleColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22)),
      title: Text(title, style: TextStyle(color: titleColor, fontSize: 13)),
      subtitle: Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }
}