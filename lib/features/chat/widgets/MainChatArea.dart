// ignore_file: file_names
import 'package:flutter/material.dart';
import '../../profile/FriendProfileScreen.dart';
import '../../call/CallScreen.dart';

import '../models/chat_message.dart';
import 'HoverableMessageBubble.dart';
import 'ChatInputArea.dart'; 
// 🎯 IMPORT THÊM ĐỂ MỞ PROFILE
import '../../contacts/ContactsController.dart'; 

class MainChatArea extends StatefulWidget {
  const MainChatArea({super.key});

  @override
  State<MainChatArea> createState() => _MainChatAreaState();
}

class _MainChatAreaState extends State<MainChatArea> {
  final ScrollController _scrollController = ScrollController();
  bool _showInfoPanel = false;
  
  // 🎯 KHAI BÁO CONTROLLER TẠI ĐÂY
  final ContactsController _contactController = ContactsController();

  List<ChatMessage> messages = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _contactController.dispose(); // Nhớ giải phóng bộ nhớ
    super.dispose();
  }

  // 🎯 ĐÃ BỔ SUNG ĐỦ THAM SỐ CHO PROFILE CẢI TIẾN
  void _openUserProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
      userId: 'mock_user_id', // ID tạm thời cho màn hình Chat giả lập
      userName: 'Trần Thị B', 
      avatarUrl: 'https://i.pravatar.cc/150?img=20', 
      bio: 'Yêu màu hồng, ghét sự giả dối 🌸', 
      
      // 🎯 ĐÃ ĐỔI TÊN BIẾN THEO CHUẨN 3 TRẠNG THÁI MỚI
      initialRelationStatus: 'friend', 
      
      contactController: _contactController, 
    )));
  }

  void _addMessage(ChatMessage msg) {
    setState(() {
      messages.add(msg);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    return Container(
      color: bgColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // CỘT TRÁI: KHU VỰC CHAT CHÍNH
          // ==========================================
          Expanded(
            child: Column(
              children: [
                _buildHeader(surfaceColor, textColor, primaryColor),
                
                // DANH SÁCH TIN NHẮN
                Expanded(
                  child: messages.isEmpty 
                    ? _buildEmptyChatState(textColor) 
                    : RawScrollbar(
                        controller: _scrollController,
                        thumbColor: textColor.withValues(alpha: 0.2),
                        radius: const Radius.circular(8),
                        thickness: 6,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return HoverableMessageBubble(message: messages[index]);
                          },
                        ),
                      ),
                ),
                
                ChatInputArea(
                  onSendMessage: (text) {
                    _addMessage(ChatMessage(text: text, isMe: true, time: 'Vừa xong'));
                  },
                  onSendGif: (url) {
                    _addMessage(ChatMessage(text: url, isMe: true, time: 'Vừa xong', type: 'image'));
                  },
                  onSendVoice: (duration) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi tin nhắn thoại ($duration giây)'), behavior: SnackBarBehavior.floating));
                  },
                ),
              ],
            ),
          ),

          // ==========================================
          // CỘT PHẢI: BẢNG THÔNG TIN
          // ==========================================
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(sizeFactor: animation, axis: Axis.horizontal, axisAlignment: -1.0, child: child);
            },
            child: _showInfoPanel ? _buildRightInfoPanelWrapper(textColor, primaryColor, surfaceColor) : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }

  // --- CÁC HÀM UI CỦA MAIN CHAT ---
  Widget _buildEmptyChatState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Chưa có tin nhắn nào.\nHãy gửi lời chào đến Trần Thị B!', textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildHeader(Color surfaceColor, Color textColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(color: surfaceColor, border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _openUserProfile,
              child: Stack(
                children: [
                  const CircleAvatar(radius: 22, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=20')),
                  Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: surfaceColor, width: 2)))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: _openUserProfile, child: Text('Trần Thị B', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)))),
                Text('Đang hoạt động', style: TextStyle(fontSize: 13, color: primaryColor)),
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.call_outlined, color: primaryColor), onPressed: () => Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (context, animation, secondaryAnimation) => const CallScreen(isVideoCall: false, userName: 'Trần Thị B', avatarUrl: 'https://i.pravatar.cc/150?img=20')))),
          IconButton(icon: Icon(Icons.videocam_outlined, color: primaryColor), onPressed: () => Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (context, animation, secondaryAnimation) => const CallScreen(isVideoCall: true, userName: 'Trần Thị B', avatarUrl: 'https://i.pravatar.cc/150?img=20')))),
          IconButton(icon: Icon(_showInfoPanel ? Icons.info_rounded : Icons.info_outline, color: _showInfoPanel ? primaryColor : textColor.withValues(alpha: 0.6)), onPressed: () => setState(() => _showInfoPanel = !_showInfoPanel)),
        ],
      ),
    );
  }

  Widget _buildRightInfoPanelWrapper(Color textColor, Color primaryColor, Color surfaceColor) {
    return Container(
      key: const ValueKey('panel'), width: 320, 
      decoration: BoxDecoration(color: surfaceColor, border: Border(left: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
      child: _buildRightInfoPanel(textColor, primaryColor),
    );
  }

  Widget _buildRightInfoPanel(Color textColor, Color primaryColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),
          const CircleAvatar(radius: 48, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=20')),
          const SizedBox(height: 16),
          Text('Trần Thị B', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          Text('Trực tuyến', style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoActionBtn(Icons.person_outline, 'Hồ sơ', textColor, onTap: _openUserProfile),
              const SizedBox(width: 24),
              _buildInfoActionBtn(Icons.notifications_off_outlined, 'Tắt âm', textColor),
              const SizedBox(width: 24),
              _buildInfoActionBtn(Icons.search_rounded, 'Tìm kiếm', textColor),
            ],
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildInfoActionBtn(IconData icon, String label, Color textColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle), child: Icon(icon, color: textColor.withValues(alpha: 0.8))),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}