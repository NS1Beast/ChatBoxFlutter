// ignore_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'chat_message.dart'; // 🎯 Đã sửa lại đường dẫn import cho đúng thư mục hiện tại

class HoverableMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final Function(ChatMessage)? onReply;
  final Function(String)? onReact;

  const HoverableMessageBubble({
    super.key, 
    required this.message,
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
        PopupMenuItem<String>(value: 'delete', child: _buildMenuItem(Icons.delete_outline_rounded, 'Thu hồi', Colors.redAccent)),
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
    }
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
          
          // 🎯 1. KHỐI HIỂN THỊ TIN NHẮN BỊ TRẢ LỜI (Nằm phía trên)
          if (widget.message.replyToText != null)
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

          // 🎯 2. KHỐI TIN NHẮN CHÍNH
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isMe && _isHovered) _buildActionIcons(textColor),
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(left: isMe ? 8 : 0, right: isMe ? 0 : 8),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: widget.message.type == 'image' ? Colors.transparent : (isMe ? primaryColor : surfaceColor),
                      borderRadius: borderRadius,
                      boxShadow: widget.message.type == 'image' ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                        onTap: _toggleDetails, 
                        onSecondaryTap: () => _showContextMenu(context), 
                        onLongPress: () => _showContextMenu(context), 
                        child: Padding(
                          padding: widget.message.type == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Text hoặc Ảnh
                              if (widget.message.type == 'image')
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
                                  )
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
                              
                              // 🎯 3. KHỐI HIỂN THỊ CẢM XÚC (REACTIONS) DƯỚI ĐÍT TEXT
                              if (widget.message.reactions.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
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
                if (!isMe && _isHovered) _buildActionIcons(textColor),
              ],
            ),
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: isMe ? Alignment.topRight : Alignment.topLeft, 
            child: _showDetails 
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