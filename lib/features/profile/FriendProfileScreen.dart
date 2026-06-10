// ignore_file: file_names
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../contacts/ContactsController.dart';
import '../chat/widgets/MainChatArea.dart'; // 🎯 IMPORT ĐỂ ĐIỀU HƯỚNG

class FriendProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String avatarUrl;
  final String coverImageUrl;
  final String bio;
  
  final String initialRelationStatus; 
  
  final ContactsController contactController;
  final Function(String userId)? onStartChat;

  const FriendProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    this.coverImageUrl = '',
    required this.bio,
    this.initialRelationStatus = 'none', 
    required this.contactController,
    this.onStartChat, 
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late String _relationStatus; 
  
  Uint8List? _friendAvatarBytes;
  Uint8List? _friendCoverBytes;

  @override
  void initState() {
    super.initState();
    _relationStatus = widget.initialRelationStatus;
    _loadFriendLocalData(); 
  }

  Future<void> _loadFriendLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    String? avatarBase64 = prefs.getString('${widget.userId}_avatarBytes');
    String? coverBase64 = prefs.getString('${widget.userId}_coverBytes');

    if (mounted) {
      setState(() {
        if (avatarBase64 != null && avatarBase64.isNotEmpty) {
          _friendAvatarBytes = base64Decode(avatarBase64);
        }
        if (coverBase64 != null && coverBase64.isNotEmpty) {
          _friendCoverBytes = base64Decode(coverBase64);
        }
      });
    }
  }

  ImageProvider _getAvatar() {
    if (_friendAvatarBytes != null) {
      return MemoryImage(_friendAvatarBytes!);
    } 
    if (widget.avatarUrl.isNotEmpty && widget.avatarUrl.toLowerCase() != 'null') {
      if (widget.avatarUrl.startsWith('data:image')) {
        final split = widget.avatarUrl.split(',');
        if (split.length == 2) {
          try {
            return MemoryImage(base64Decode(split[1]));
          } catch (e) {
            debugPrint("Lỗi giải mã Base64 Avatar: $e");
          }
        }
      } else {
        return NetworkImage(widget.avatarUrl);
      }
    }
    return NetworkImage('https://i.pravatar.cc/150?u=${widget.userId}');
  }

  ImageProvider? _getCover() {
    if (_friendCoverBytes != null) return MemoryImage(_friendCoverBytes!);
    if (widget.coverImageUrl.isNotEmpty && widget.coverImageUrl.toLowerCase() != 'null') {
      if (widget.coverImageUrl.startsWith('data:image')) {
        final split = widget.coverImageUrl.split(',');
        if (split.length == 2) {
          try {
            return MemoryImage(base64Decode(split[1]));
          } catch (e) {
            debugPrint("Lỗi giải mã Base64 Cover: $e");
          }
        }
      } else {
        return NetworkImage(widget.coverImageUrl);
      }
    }
    return null;
  }

  void _toggleFriendStatusFromPanel() async {
    String newStatus = await widget.contactController.toggleFriendStatus(widget.userId);

    if (mounted) {
      setState(() => _relationStatus = newStatus);
      String message = "";
      if (newStatus == 'pending') message = 'Đã gửi yêu cầu kết bạn đến ${widget.userName}!';
      else if (newStatus == 'friend') message = 'Bạn và ${widget.userName} đã trở thành bạn bè!';
      else message = 'Đã hủy kết bạn / yêu cầu với ${widget.userName}.';

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: newStatus == 'pending' ? Colors.orange : (newStatus == 'friend' ? Colors.green : Colors.redAccent), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
    }
  }

  void _showAddToGroupModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thêm vào nhóm', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(leading: const CircleAvatar(child: Icon(Icons.group)), title: const Text('Hội anh em Coder'), onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm ${widget.userName} vào Hội anh em Coder'))); }),
              ListTile(leading: const CircleAvatar(child: Icon(Icons.group)), title: const Text('Nhóm Đồ án AI'), onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm ${widget.userName} vào Nhóm Đồ án AI'))); }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final primaryColor = Theme.of(context).colorScheme.primary;

    ImageProvider? finalCover = _getCover();
    bool isFriend = (_relationStatus == 'friend');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text('Hồ sơ liên hệ', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 160, width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                              image: finalCover != null ? DecorationImage(image: finalCover, fit: BoxFit.cover) : null,
                            ),
                            child: finalCover == null ? const Center(child: Icon(Icons.auto_awesome, color: Colors.white24, size: 80)) : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
                          child: CircleAvatar(radius: 56, backgroundColor: Colors.grey[300], backgroundImage: _getAvatar()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(widget.userName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text(widget.bio, style: TextStyle(color: subtitleColor, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HoverableActionCard(
                        icon: Icons.chat_bubble_rounded, label: 'Nhắn tin',
                        primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor,
                        onTap: () {
                          Navigator.pop(context); 
                          if (widget.onStartChat != null) widget.onStartChat!(widget.userId); 
                        },
                      ),
                      const SizedBox(width: 16),

                      // 🎯 ĐÃ FIX: Điều hướng sang Chat kèm lệnh Gọi thoại
                      _HoverableActionCard(
                        icon: Icons.call_rounded, label: 'Gọi thoại',
                        primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor,
                        onTap: () {
                          Navigator.pop(context); // Tắt Profile
                          if (widget.onStartChat != null) widget.onStartChat!(widget.userId);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainChatArea(
                                chatId: widget.userId, chatName: widget.userName, chatAvatar: widget.avatarUrl,
                                autoStartVoiceCall: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),

                      // 🎯 ĐÃ FIX: Điều hướng sang Chat kèm lệnh Gọi video
                      _HoverableActionCard(
                        icon: Icons.videocam_rounded, label: 'Gọi video',
                        primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor,
                        onTap: () {
                          Navigator.pop(context); 
                          if (widget.onStartChat != null) widget.onStartChat!(widget.userId);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainChatArea(
                                chatId: widget.userId, chatName: widget.userName, chatAvatar: widget.avatarUrl,
                                autoStartVideoCall: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24), 

                  SizedBox(
                    width: double.infinity, height: 56, 
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _relationStatus == 'friend'
                          ? OutlinedButton.icon(key: const ValueKey('unfriend'), onPressed: _toggleFriendStatusFromPanel, icon: const Icon(Icons.person_remove_rounded, size: 22), label: const FittedBox(child: Text('Hủy kết bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size.fromHeight(56)))
                          : _relationStatus == 'pending'
                            ? FilledButton.icon(key: const ValueKey('pending'), onPressed: _toggleFriendStatusFromPanel, icon: const Icon(Icons.access_time_rounded, size: 22), label: const FittedBox(child: Text('Đã gửi yêu cầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), style: FilledButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size.fromHeight(56)))
                            : _relationStatus == 'awaiting'
                              ? FilledButton.icon(key: const ValueKey('awaiting'), onPressed: _toggleFriendStatusFromPanel, icon: const Icon(Icons.check_circle_outline_rounded, size: 22), label: const FittedBox(child: Text('Chấp nhận kết bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), style: FilledButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size.fromHeight(56)))
                              : FilledButton.icon(key: const ValueKey('add_friend'), onPressed: _toggleFriendStatusFromPanel, icon: const Icon(Icons.person_add_rounded, size: 22), label: const FittedBox(child: Text('Thêm bạn bè', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), style: FilledButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size.fromHeight(56))),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader('Thông tin', textColor),
                  Container(
                    decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      children: [
                        _buildInfoTile(context, Icons.info_outline, 'Giới thiệu', widget.bio, subtitleColor, textColor),
                        const Divider(height: 1, indent: 56, endIndent: 24),
                        _buildInfoTile(context, Icons.email_outlined, 'Email', isFriend ? 'Đã liên kết' : 'Chỉ bạn bè mới có thể xem', subtitleColor, textColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader('Tùy chọn', textColor),
                  Container(
                    decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      children: [
                        _buildActionTile(context, Icons.group_add_rounded, 'Thêm vào nhóm', primaryColor, onTap: _showAddToGroupModal),
                        const Divider(height: 1, indent: 56, endIndent: 24),
                        _buildActionTile(context, Icons.block_rounded, 'Chặn người dùng này', Colors.redAccent, onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chặn liên hệ này!'), backgroundColor: Colors.red)); }),
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

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(padding: const EdgeInsets.only(bottom: 12, left: 8), child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.5), letterSpacing: 1.2))));
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle, Color subtitleColor, Color textColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22)),
      title: Text(title, style: TextStyle(color: subtitleColor, fontSize: 13)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, Color color, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
      title: Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

class _HoverableActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;
  final VoidCallback onTap;

  const _HoverableActionCard({
    required this.icon, required this.label, required this.primaryColor, required this.surfaceColor, required this.textColor, required this.onTap,
  });

  @override
  State<_HoverableActionCard> createState() => _HoverableActionCardState();
}

class _HoverableActionCardState extends State<_HoverableActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isHovered ? widget.primaryColor.withValues(alpha: 0.1) : widget.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03), blurRadius: _isHovered ? 15 : 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Icon(widget.icon, color: widget.primaryColor, size: 28),
                const SizedBox(height: 8),
                Text(widget.label, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}