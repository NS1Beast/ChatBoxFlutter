import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'FullScreenImageViewer.dart'; // Tuỳ chỉnh đường dẫn nếu cần

class HoverableMessageBubble extends StatefulWidget {
  final ChatMessage message;
  const HoverableMessageBubble({super.key, required this.message});

  @override
  State<HoverableMessageBubble> createState() => _HoverableMessageBubbleState();
}

class _HoverableMessageBubbleState extends State<HoverableMessageBubble> {
  bool _isHovered = false;
  Offset _tapPosition = Offset.zero;

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