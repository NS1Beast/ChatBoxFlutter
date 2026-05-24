// ignore_file: file_names
import 'package:flutter/material.dart';

class FriendProfileScreen extends StatefulWidget {
  final String userName;
  final String avatarUrl;
  final String bio;
  final bool initialIsFriend;

  const FriendProfileScreen({
    super.key,
    required this.userName,
    required this.avatarUrl,
    required this.bio,
    required this.initialIsFriend,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late bool _isFriend;

  @override
  void initState() {
    super.initState();
    _isFriend = widget.initialIsFriend;
  }

  void _toggleFriendStatus() {
    setState(() {
      _isFriend = !_isFriend;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFriend ? 'Đã thêm ${widget.userName} vào danh bạ!' : 'Đã hủy kết bạn với ${widget.userName}.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final primaryColor = Theme.of(context).colorScheme.primary;

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
          'Hồ sơ của ${widget.userName}',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // Vẫn giữ max width 600 để UI ko bị bè ra trên Desktop
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
                                colors: [primaryColor, primaryColor.withValues(alpha: 0.6)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white24, size: 80),
                          ),
                        ),
                        // Avatar
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
                          child: CircleAvatar(radius: 56, backgroundImage: NetworkImage(widget.avatarUrl)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==========================================
                  // 2. THÔNG TIN CƠ BẢN
                  // ==========================================
                  Text(
                    widget.userName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.bio,
                    style: TextStyle(color: subtitleColor, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 3. CÁC NÚT TƯƠNG TÁC (KẾT BẠN / NHẮN TIN)
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nút Hủy/Thêm bạn bè
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isFriend 
                            ? OutlinedButton.icon(
                                key: const ValueKey('unfriend'),
                                onPressed: _toggleFriendStatus,
                                icon: const Icon(Icons.person_remove_rounded, size: 18),
                                label: const Text('Hủy kết bạn', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              )
                            : FilledButton.icon(
                                key: const ValueKey('add_friend'),
                                onPressed: _toggleFriendStatus,
                                icon: const Icon(Icons.person_add_rounded, size: 18),
                                label: const Text('Thêm bạn bè', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                        ),
                      ),
                      
                      // Nút Nhắn tin (Luôn hiện hoặc chỉ hiện khi là bạn tùy logic của bạn)
                      if (_isFriend) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context), // Trở lại màn hình chat
                            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                            label: const Text('Nhắn tin', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // 4. THẺ THÔNG TIN CHI TIẾT (Lược bỏ Cài đặt/Đăng xuất)
                  // ==========================================
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(context, Icons.email_outlined, 'Email', 'an_danh@prochat.com', subtitleColor, textColor),
                        const Divider(height: 1, indent: 56, endIndent: 24),
                        _buildInfoTile(context, Icons.phone_outlined, 'Số điện thoại', '*********89', subtitleColor, textColor),
                        const Divider(height: 1, indent: 56, endIndent: 24),
                        _buildInfoTile(context, Icons.location_on_outlined, 'Vị trí', 'Hà Nội, Việt Nam', subtitleColor, textColor),
                        const Divider(height: 1, indent: 56, endIndent: 24),
                        _buildInfoTile(context, Icons.group_outlined, 'Bạn chung', '12 người', subtitleColor, textColor),
                      ],
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

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle, Color subtitleColor, Color textColor) {
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
      title: Text(title, style: TextStyle(color: subtitleColor, fontSize: 13)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }
}