import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../profile/FriendProfileScreen.dart';
import '../../call/CallScreen.dart';
import 'FullScreenImageViewer.dart';

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
  
  bool _showInfoPanel = false;
  bool _isTyping = false;
  
  // ==========================================
  // BIẾN TRẠNG THÁI GHI ÂM
  // ==========================================
  bool _isRecording = false;
  int _recordDuration = 0; // Tính bằng giây
  Timer? _timer;

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
    _timer?.cancel();
    super.dispose();
  }

  void _openUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FriendProfileScreen(
          userName: 'Trần Thị B',
          avatarUrl: 'https://i.pravatar.cc/150?img=20',
          bio: 'Yêu màu hồng, ghét sự giả dối 🌸',
          initialIsFriend: true,
        ),
      ),
    );
  }

  // --- HÀM XỬ LÝ GHI ÂM ---
  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordDuration = 0;
    });
    // Đếm giờ mỗi giây
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  void _stopRecording({required bool send}) {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
    
    if (send) {
      // Giả lập gửi tin nhắn thoại (Hiện tại chỉ show Toast)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi tin nhắn thoại!'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // Format số giây thành chuỗi 00:00
  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
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
                // 1. HEADER (Giữ nguyên như cũ)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                  ),
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
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(onTap: _openUserProfile, child: Text('Trần Thị B', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
                            ),
                            Text('Đang hoạt động', style: TextStyle(fontSize: 13, color: primaryColor)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.call_outlined, color: primaryColor), 
                        onPressed: () => Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (_, __, ___) => const CallScreen(isVideoCall: false, userName: 'Trần Thị B', avatarUrl: 'https://i.pravatar.cc/150?img=20')))
                      ),
                      IconButton(
                        icon: Icon(Icons.videocam_outlined, color: primaryColor), 
                        onPressed: () => Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (_, __, ___) => const CallScreen(isVideoCall: true, userName: 'Trần Thị B', avatarUrl: 'https://i.pravatar.cc/150?img=20')))
                      ),
                      IconButton(
                        icon: Icon(_showInfoPanel ? Icons.info_rounded : Icons.info_outline, color: _showInfoPanel ? primaryColor : textColor.withValues(alpha: 0.6)), 
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
                
                // 3. KHUNG NHẬP LIỆU (TÍCH HỢP HIỆU ỨNG GHI ÂM)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  color: surfaceColor,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    // Chuyển đổi giữa Ô gõ chữ và Thanh ghi âm
                    child: _isRecording 
                        ? _buildRecordingBar(textColor, primaryColor)
                        : _buildChatInputBar(textColor, primaryColor),
                  ),
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
            child: _showInfoPanel 
                ? _buildRightInfoPanelWrapper(textColor, primaryColor, surfaceColor) 
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }

  // --- UI GIAO DIỆN CHAT BÌNH THƯỜNG ---
  Widget _buildChatInputBar(Color textColor, Color primaryColor) {
    return Row(
      key: const ValueKey('chat_input'),
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
                  key: const ValueKey('mic'), 
                  onPressed: _startRecording, // BẤM ĐỂ BẮT ĐẦU GHI ÂM
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, elevation: 0, mini: true,
                  child: Icon(Icons.mic_none_rounded, color: textColor, size: 22),
                ),
        ),
      ],
    );
  }

  // --- UI THANH GHI ÂM ĐANG CHẠY ---
  Widget _buildRecordingBar(Color textColor, Color primaryColor) {
    return Row(
      key: const ValueKey('recording_bar'),
      children: [
        // Nút Hủy (Thùng rác)
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: () => _stopRecording(send: false),
          tooltip: 'Hủy ghi âm',
        ),
        const SizedBox(width: 12),
        
        // Thời gian & Hiệu ứng chớp đỏ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              _BlinkingDot(),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Sóng âm (Sẽ giãn ra chiếm chỗ trống)
        Expanded(child: VoiceWaveform(primaryColor: primaryColor)),
        
        const SizedBox(width: 16),
        // Nút Gửi thoại
        FloatingActionButton(
          onPressed: () => _stopRecording(send: true),
          backgroundColor: primaryColor,
          elevation: 2,
          mini: true,
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  // --- CÁC HÀM XÂY DỰNG PANEL BÊN PHẢI (Giữ nguyên) ---
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

// ==========================================
// WIDGET CON: Chấm đỏ nhấp nháy
// ==========================================
class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
    );
  }
}

// ==========================================
// WIDGET CON: Sóng âm tự chế (Waveform)
// ==========================================
class VoiceWaveform extends StatefulWidget {
  final Color primaryColor;
  const VoiceWaveform({super.key, required this.primaryColor});

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform> {
  late Timer _timer;
  final Random _random = Random();
  // Khởi tạo 30 cột sóng với độ cao ngẫu nhiên ban đầu
  List<double> _heights = List.generate(30, (index) => 5.0);

  @override
  void initState() {
    super.initState();
    // Thay đổi độ cao các sóng mỗi 150ms để tạo cảm giác có người đang nói
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        _heights = List.generate(30, (index) => _random.nextDouble() * 25 + 5);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30, // Chiều cao tối đa của vùng sóng âm
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _heights.map((height) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.6), // Màu theo theme
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ==========================================
// WIDGET CON: Bong bóng tin nhắn
// ==========================================
class _HoverableMessageBubble extends StatefulWidget {
  final ChatMessage message;
  const _HoverableMessageBubble({required this.message});

  @override
  State<_HoverableMessageBubble> createState() => _HoverableMessageBubbleState();
}

class _HoverableMessageBubbleState extends State<_HoverableMessageBubble> {
  bool _isHovered = false;
  Offset _tapPosition = Offset.zero;

  void _showContextMenu(BuildContext context) async {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;
  final textColor = Theme.of(context).colorScheme.onSurface;

  await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      _tapPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    ),
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 8,
    items: <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'reply',
        child: _buildMenuItem(
          Icons.reply_rounded,
          'Trả lời',
          textColor,
        ),
      ),
      PopupMenuItem<String>(
        value: 'copy',
        child: _buildMenuItem(
          Icons.copy_rounded,
          'Sao chép',
          textColor,
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'delete',
        child: _buildMenuItem(
          Icons.delete_outline_rounded,
          'Thu hồi',
          Colors.redAccent,
        ),
      ),
    ],
  );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color) {
    return Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 12), Text(title, style: TextStyle(color: color, fontSize: 14))]);
  }

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
              child: GestureDetector(
                onSecondaryTapDown: (details) => _tapPosition = details.globalPosition,
                onSecondaryTap: () => _showContextMenu(context),
                onLongPressStart: (details) => _tapPosition = details.globalPosition,
                onLongPress: () => _showContextMenu(context),
                child: Container(
                  margin: EdgeInsets.only(left: isMe ? 8 : 0, right: isMe ? 0 : 8),
                  padding: widget.message.type == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: isMe ? primaryColor : surfaceColor,
                    borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (widget.message.type == 'image')
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (context, animation, _) => FadeTransition(opacity: animation, child: FullScreenImageViewer(imageUrl: widget.message.text, heroTag: 'image_${widget.message.text}_${widget.message.time}')))),
                            child: Hero(tag: 'image_${widget.message.text}_${widget.message.time}', child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(widget.message.text, fit: BoxFit.cover))),
                          ),
                        )
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