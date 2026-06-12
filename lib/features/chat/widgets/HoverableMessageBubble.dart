// ignore_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'chat_message.dart'; 

class HoverableMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onRevoke;       // 🎯 Thêm callback thu hồi
  final VoidCallback onDeleteForMe;  // 🎯 Thêm callback xóa cục bộ
  final bool canRevoke;              // 🎯 Biến check thời gian vàng 5 phút từ cha truyền xuống
  final Function(ChatMessage)? onReply;
  final Function(String)? onReact;

  const HoverableMessageBubble({
    super.key, 
    required this.message,
    required this.onRevoke,
    required this.onDeleteForMe,
    required this.canRevoke,
    this.onReply,
    this.onReact,
  });

  @override
  State<HoverableMessageBubble> createState() => _HoverableMessageBubbleState();
}

class _HoverableMessageBubbleState extends State<HoverableMessageBubble> {
  bool _isHovered = false;
  Offset _tapPosition = Offset.zero;
  bool _showDetails = false; 

  final List<String> _quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  void _toggleDetails() {
    setState(() => _showDetails = !_showDetails);
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showContextMenu(BuildContext context) async {
    // Nếu tin nhắn đã thu hồi rồi thì không cho bật menu thao tác nữa
    if (widget.message.type == 'revoked') return;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(_tapPosition & const Size(40, 40), Offset.zero & overlay.size),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false, 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _quickEmojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context); 
                  if (widget.onReact != null) widget.onReact!(emoji);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'reply', child: _buildMenuItem(Icons.reply_rounded, 'Trả lời', textColor)),
        PopupMenuItem<String>(value: 'copy', child: _buildMenuItem(Icons.copy_rounded, 'Sao chép', textColor)),
        const PopupMenuDivider(),
        
        // 🎯 THIẾT KẾ ĐIỀU KIỆN RẼ NHÁNH BẢO MẬT THEO ĐÚNG YÊU CẦU CỦA ÔNG
        if (widget.canRevoke)
          PopupMenuItem<String>(value: 'revoke', child: _buildMenuItem(Icons.undo_rounded, 'Thu hồi', Colors.orangeAccent))
        else
          PopupMenuItem<String>(value: 'delete_for_me', child: _buildMenuItem(Icons.delete_outline_rounded, 'Xóa ở phía tôi', Colors.redAccent)),
      ],
    );

    if (result == 'reply' && widget.onReply != null) {
      widget.onReply!(widget.message);
    } else if (result == 'copy') {
      Clipboard.setData(ClipboardData(text: widget.message.text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã sao chép tin nhắn'), duration: Duration(seconds: 1)),
        );
      }
    } else if (result == 'revoke') {
      widget.onRevoke(); // Kích hoạt lệnh thu hồi trên máy chủ & cả 2 bên máy
    } else if (result == 'delete_for_me') {
      widget.onDeleteForMe(); // Kích hoạt giấu tin nhắn cục bộ phía mình
    }
  }

  Widget _buildMenuItem(IconData icon, String title, Color color) {
    return Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 12), Text(title, style: TextStyle(color: color, fontSize: 14))]);
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isMe;
    final isRevoked = widget.message.type == 'revoked'; // Check cờ thu hồi
    
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18), 
      topRight: const Radius.circular(18), 
      bottomLeft: Radius.circular(isMe ? 18 : 4), 
      bottomRight: Radius.circular(isMe ? 4 : 18)
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8), 
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          
          // 1. KHỐI HIỂN THỊ TIN NHẮN BỊ TRẢ LỜI (Ẩn đi nếu tin nhắn chính đã bị thu hồi)
          if (widget.message.replyToText != null && !isRevoked)
            Container(
              margin: EdgeInsets.only(bottom: 4, left: isMe ? 40 : 12, right: isMe ? 12 : 40),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? primaryColor.withValues(alpha: 0.15) : textColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: isMe ? primaryColor.withValues(alpha: 0.5) : textColor.withValues(alpha: 0.3), width: 3)),
              ),
              child: Text(
                widget.message.replyToText!,
                maxLines: 2, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.7)),
              ),
            ),

          // 2. KHỐI TIN NHẮN CHÍNH
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isMe && _isHovered && !isRevoked) _buildActionIcons(textColor),
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(left: isMe ? 8 : 0, right: isMe ? 0 : 8),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      // Nếu bị thu hồi thì cho hình nền xám trong suốt, nếu không giữ nguyên màu cũ của ông
                      color: isRevoked 
                          ? textColor.withValues(alpha: 0.05) 
                          : (widget.message.type == 'image' ? Colors.transparent : (isMe ? primaryColor : surfaceColor)),
                      borderRadius: borderRadius,
                      boxShadow: (widget.message.type == 'image' || isRevoked) ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: borderRadius,
                        hoverColor: textColor.withValues(alpha: 0.05),
                        splashColor: textColor.withValues(alpha: 0.1),
                        highlightColor: textColor.withValues(alpha: 0.1),
                        onTapDown: _storePosition, 
                        onSecondaryTapDown: _storePosition, 
                        onTap: isRevoked ? null : _toggleDetails, // Khóa tap xem chi tiết nếu đã thu hồi
                        onSecondaryTap: () => _showContextMenu(context), 
                        onLongPress: () => _showContextMenu(context), 
                        child: Padding(
                          padding: (widget.message.type == 'image' && !isRevoked) ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // 🎯 GIAO DIỆN HIỂN THỊ KHI TIN NHẮN BỊ THU HỒI
                              if (isRevoked)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.block_flipped, size: 14, color: textColor.withValues(alpha: 0.35)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tin nhắn đã được thu hồi',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: textColor.withValues(alpha: 0.35),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              // Nếu trạng thái bình thường: Render Text hoặc Ảnh của ông
                              else if (widget.message.type == 'image')
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14), 
                                  child: Image.network(
                                    widget.message.text, 
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200, width: 250,
                                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1)),
                                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 150, width: 200,
                                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1)),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [Icon(Icons.broken_image_rounded, color: Colors.redAccent), SizedBox(height: 8), Text('Lỗi ảnh', style: TextStyle(color: Colors.redAccent))],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  widget.message.text, 
                                  style: TextStyle(
                                    color: isMe ? Colors.white : textColor, 
                                    fontSize: 15, 
                                    height: 1.4,
                                    fontFamilyFallback: const ['Segoe UI Emoji', 'Apple Color Emoji', 'Noto Color Emoji'],
                                  )
                                ),
                              
                              // 3. KHỐI HIỂN THỊ CẢM XÚC (REACTIONS)
                              if (widget.message.reactions.isNotEmpty && !isRevoked)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 6, runSpacing: 4,
                                    children: widget.message.reactions.entries.map((e) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isMe ? Colors.black.withValues(alpha: 0.2) : textColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(e.key, style: const TextStyle(fontSize: 14)), 
                                            const SizedBox(width: 4),
                                            Text('${e.value}', style: TextStyle(fontSize: 12, color: isMe ? Colors.white : textColor, fontWeight: FontWeight.bold)), 
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isMe && _isHovered && !isRevoked) _buildActionIcons(textColor),
              ],
            ),
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: isMe ? Alignment.topRight : Alignment.topLeft, 
            child: (_showDetails && !isRevoked) 
              ? Padding(
                  padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 8, right: isMe ? 8 : 0, bottom: 4),
                  child: _buildMessageStatusDetails(textColor, primaryColor),
                ) 
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStatusDetails(Color textColor, Color primaryColor) {
    bool isSending = widget.message.time == 'Đang gửi...';
    String displayTime = isSending ? 'Đang gửi' : widget.message.time; 
    IconData statusIcon = Icons.check_circle_outline_rounded; 
    Color iconColor = textColor.withValues(alpha: 0.5);

    if (isSending) {
      statusIcon = Icons.radio_button_unchecked_rounded; 
    } else {
      statusIcon = Icons.check_circle_rounded; 
      iconColor = primaryColor; 
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.message.isMe) ...[
          Text(displayTime, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
        ] 
        else ...[
          Text(displayTime, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Text('•', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 4),
          Icon(statusIcon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(isSending ? 'Đang gửi' : 'Đã gửi', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5))),
        ],
      ],
    );
  }

  Widget _buildActionIcons(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(Icons.reply_rounded, size: 20, color: textColor.withValues(alpha: 0.5)), onPressed: () {
          if (widget.onReply != null) widget.onReply!(widget.message);
        }, padding: const EdgeInsets.all(8)),
        IconButton(icon: Icon(Icons.add_reaction_outlined, size: 20, color: textColor.withValues(alpha: 0.5)), onPressed: () => _showContextMenu(context), padding: const EdgeInsets.all(8)),
      ],
    );
  }
}