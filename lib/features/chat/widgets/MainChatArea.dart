import 'package:flutter/material.dart';
import '../../call/CallScreen.dart';
// Model mô phỏng tin nhắn
class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final String type;

  ChatMessage({required this.text, required this.isMe, required this.time, this.type = 'text'});
}

class MainChatArea extends StatefulWidget {
  const MainChatArea({super.key});

  @override
  State<MainChatArea> createState() => _MainChatAreaState();
}

class _MainChatAreaState extends State<MainChatArea> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _msgController = TextEditingController();
  bool _isTyping = false;
  
  // BIẾN TRẠNG THÁI: Đóng/Mở bảng thông tin bên phải
  bool _showInfoPanel = false;

  final List<ChatMessage> messages = [
    ChatMessage(text: 'Chào bạn, dự án dạo này sao rồi?', isMe: false, time: '10:30 AM'),
    ChatMessage(text: 'Mọi thứ đang đi đúng hướng. Tui vừa thiết kế xong cấu trúc MVC cho ứng dụng.', isMe: true, time: '10:32 AM'),
    ChatMessage(text: 'Tuyệt quá! Gửi tui xem thử một tấm ảnh giao diện được không?', isMe: false, time: '10:33 AM'),
    ChatMessage(text: 'https://picsum.photos/seed/ui/400/300', isMe: true, time: '10:35 AM', type: 'image'),
    ChatMessage(text: 'Nhìn xịn thật sự, đúng chuẩn Mac-style luôn!', isMe: false, time: '10:36 AM'),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _msgController.dispose();
    super.dispose();
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
                // 1. HEADER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          const CircleAvatar(radius: 22, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=20')),
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green, shape: BoxShape.circle,
                                border: Border.all(color: surfaceColor, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trần Thị B', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                            Text('Đang hoạt động', style: TextStyle(fontSize: 13, color: primaryColor)),
                          ],
                        ),
                      ),
                      IconButton(
                          icon: Icon(Icons.call_outlined, color: primaryColor), 
                          onPressed: () {
                            Navigator.push(
                              context, 
                              PageRouteBuilder(
                                opaque: false, // Để nó phủ lên trên màn hình hiện tại
                                pageBuilder: (_, __, ___) => const CallScreen(
                                  isVideoCall: false,
                                  userName: 'Trần Thị B',
                                  avatarUrl: 'https://i.pravatar.cc/150?img=20',
                                ),
                              ),
                            );
                          }
                        ),
                        IconButton(
                          icon: Icon(Icons.videocam_outlined, color: primaryColor), 
                          onPressed: () {
                            Navigator.push(
                              context, 
                              PageRouteBuilder(
                                opaque: false, 
                                pageBuilder: (_, __, ___) => const CallScreen(
                                  isVideoCall: true,
                                  userName: 'Trần Thị B',
                                  avatarUrl: 'https://i.pravatar.cc/150?img=20',
                                ),
                              ),
                            );
                          }
                        ),
                      // NÚT BẬT/TẮT BẢNG THÔNG TIN
                      IconButton(
                        icon: Icon(
                          _showInfoPanel ? Icons.info_rounded : Icons.info_outline, 
                          color: _showInfoPanel ? primaryColor : textColor.withValues(alpha: 0.6)
                        ), 
                        onPressed: () => setState(() => _showInfoPanel = !_showInfoPanel),
                      ),
                    ],
                  ),
                ),
                
                // 2. KHU VỰC TIN NHẮN
                Expanded(
                  child: RawScrollbar(
                    controller: _scrollController,
                    thumbColor: textColor.withValues(alpha: 0.2),
                    radius: const Radius.circular(8),
                    thickness: 6,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _HoverableMessageBubble(message: messages[index]);
                      },
                    ),
                  ),
                ),
                
                // 3. KHUNG NHẬP LIỆU
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  color: surfaceColor,
                  child: Row(
                    children: [
                      IconButton(icon: Icon(Icons.add_circle_outline_rounded, color: textColor.withValues(alpha: 0.5)), onPressed: () {}),
                      IconButton(icon: Icon(Icons.image_outlined, color: textColor.withValues(alpha: 0.5)), onPressed: () {}),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          onChanged: (text) => setState(() => _isTyping = text.isNotEmpty),
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            suffixIcon: IconButton(icon: Icon(Icons.sentiment_satisfied_alt_rounded, color: textColor.withValues(alpha: 0.5)), onPressed: () {}),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: _isTyping
                            ? FloatingActionButton(
                                key: const ValueKey('send'), onPressed: () {},
                                backgroundColor: primaryColor, elevation: 2, mini: true,
                                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              )
                            : FloatingActionButton(
                                key: const ValueKey('mic'), onPressed: () {},
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, elevation: 0, mini: true,
                                child: Icon(Icons.mic_none_rounded, color: textColor, size: 22),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // CỘT PHẢI: BẢNG THÔNG TIN (INFO PANEL)
          // ==========================================
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                axisAlignment: -1.0,
                child: child,
              );
            },
            child: _showInfoPanel 
                ? _buildRightInfoPanelWrapper(textColor, primaryColor, surfaceColor) 
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }

  // --- WRAPPER CỐ ĐỊNH CHIỀU RỘNG BẢNG THÔNG TIN ---
  Widget _buildRightInfoPanelWrapper(Color textColor, Color primaryColor, Color surfaceColor) {
    return Container(
      key: const ValueKey('panel'),
      width: 320, // Ép cứng chiều rộng, không đổi liên tục nữa
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(left: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: _buildRightInfoPanel(textColor, primaryColor),
    );
  }

  // --- GIAO DIỆN BẢNG THÔNG TIN NỘI BỘ ---
  Widget _buildRightInfoPanel(Color textColor, Color primaryColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Avatar to
          const CircleAvatar(radius: 48, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=20')),
          const SizedBox(height: 16),
          Text('Trần Thị B', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          Text('Trực tuyến', style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          
          // Các nút thao tác nhanh
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoActionBtn(Icons.person_outline, 'Hồ sơ', textColor),
              const SizedBox(width: 24),
              _buildInfoActionBtn(Icons.notifications_off_outlined, 'Tắt âm', textColor),
              const SizedBox(width: 24),
              _buildInfoActionBtn(Icons.search_rounded, 'Tìm kiếm', textColor),
            ],
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),

          // Kho Media (Hình ảnh) dùng ExpansionTile chuẩn của Flutter
          ExpansionTile(
            title: Text('Ảnh & Video', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            initiallyExpanded: true,
            iconColor: primaryColor,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: List.generate(6, (index) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network('https://picsum.photos/seed/$index/200', fit: BoxFit.cover),
                  )),
                ),
              )
            ],
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),

          // Kho Tài liệu (File đính kèm)
          ExpansionTile(
            title: Text('File & Tài liệu', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            iconColor: primaryColor,
            children: [
              _buildFileItem('Bao_cao_AI.pdf', '2.4 MB', Icons.picture_as_pdf_rounded, Colors.redAccent, textColor),
              _buildFileItem('Thuyet_trinh.pptx', '5.1 MB', Icons.insert_chart_rounded, Colors.orange, textColor),
              _buildFileItem('Source_code.zip', '12 MB', Icons.folder_zip_rounded, Colors.blue, textColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoActionBtn(IconData icon, String label, Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: textColor.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildFileItem(String name, String size, IconData icon, Color iconColor, Color textColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
      subtitle: Text(size, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5))),
      trailing: Icon(Icons.download_rounded, color: textColor.withValues(alpha: 0.4), size: 20),
      onTap: () {},
    );
  }
}

// ==========================================
// WIDGET CON: Bong bóng tin nhắn có hiệu ứng Hover
// ==========================================
class _HoverableMessageBubble extends StatefulWidget {
  final ChatMessage message;
  const _HoverableMessageBubble({required this.message});

  @override
  State<_HoverableMessageBubble> createState() => _HoverableMessageBubbleState();
}

class _HoverableMessageBubbleState extends State<_HoverableMessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isMe;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isMe && _isHovered) _buildActionIcons(textColor),

            Flexible(
              child: Container(
                margin: EdgeInsets.only(left: isMe ? 8 : 0, right: isMe ? 0 : 8),
                padding: widget.message.type == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: isMe ? primaryColor : surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (widget.message.type == 'image')
                      ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(widget.message.text, fit: BoxFit.cover))
                    else
                      Text(widget.message.text, style: TextStyle(color: isMe ? Colors.white : textColor, fontSize: 15, height: 1.4)),
                    
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.message.time, style: TextStyle(color: isMe ? Colors.white70 : textColor.withValues(alpha: 0.5), fontSize: 11)),
                        if (isMe) ...[const SizedBox(width: 4), const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70)]
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (!isMe && _isHovered) _buildActionIcons(textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcons(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(Icons.reply_rounded, size: 20, color: textColor.withValues(alpha: 0.5)), onPressed: () {}, padding: const EdgeInsets.all(8)),
        IconButton(icon: Icon(Icons.add_reaction_outlined, size: 20, color: textColor.withValues(alpha: 0.5)), onPressed: () {}, padding: const EdgeInsets.all(8)),
      ],
    );
  }
}