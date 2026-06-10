import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class HoverableMessageBubble extends StatefulWidget {
  final ChatMessage message;
  const HoverableMessageBubble({super.key, required this.message});

  @override
  State<HoverableMessageBubble> createState() => _HoverableMessageBubbleState();
}

class _HoverableMessageBubbleState extends State<HoverableMessageBubble> {
  bool _isHovered = false;
  Offset _tapPosition = Offset.zero;
  
  bool _showDetails = false; 

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showContextMenu(BuildContext context) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final textColor = Theme.of(context).colorScheme.onSurface;

    await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(_tapPosition & const Size(40, 40), Offset.zero & overlay.size),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'reply', child: _buildMenuItem(Icons.reply_rounded, 'Trả lời', textColor)),
        PopupMenuItem<String>(value: 'copy', child: _buildMenuItem(Icons.copy_rounded, 'Sao chép', textColor)),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'delete', child: _buildMenuItem(Icons.delete_outline_rounded, 'Thu hồi', Colors.redAccent)),
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

    // Bo tròn góc tin nhắn
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
                    // 🎯 VŨ KHÍ: Dùng Material + InkWell để bắt Click chuẩn xác 100%
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: borderRadius,
                        hoverColor: textColor.withValues(alpha: 0.05),
                        splashColor: textColor.withValues(alpha: 0.1),
                        highlightColor: textColor.withValues(alpha: 0.1),
                        onTapDown: _storePosition, // Lấy vị trí để lỡ có nhấp chuột phải
                        onSecondaryTapDown: _storePosition, // Chuột phải trên Windows
                        onTap: _toggleDetails, // Click trái hiện thời gian
                        onSecondaryTap: () => _showContextMenu(context), // Click phải hiện Menu
                        child: Padding(
                          padding: widget.message.type == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
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
        IconButton(icon: Icon(Icons.reply_rounded, size: 20, color: textColor.withValues(alpha: 0.5)), onPressed: () {}, padding: const EdgeInsets.all(8)),
        IconButton(icon: Icon(Icons.add_reaction_outlined, size: 20, color: textColor.withValues(alpha: 0.5)), onPressed: () {}, padding: const EdgeInsets.all(8)),
      ],
    );
  }
}