// ignore_file: file_names
import 'package:flutter/material.dart';
import 'TimelineController.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final TimelineController _controller = TimelineController();

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Container(
          color: bgColor, // Nền xám nhạt để nổi bật các thẻ bài viết màu trắng
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    Icon(Icons.newspaper_rounded, size: 28, color: textColor),
                    const SizedBox(width: 16),
                    Text(
                      'Nhật ký hoạt động',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ),

              // Bảng tin (Feed)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680), // Cố định chiều rộng cột tin
                        child: Column(
                          children: [
                            // KHUNG ĐĂNG BÀI
                            _buildCreatePostCard(surfaceColor, textColor, primaryColor),
                            const SizedBox(height: 24),
                            
                            // DANH SÁCH BÀI VIẾT
                            ..._controller.posts.map((post) => _buildPostCard(post, surfaceColor, textColor, primaryColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // --- COMPONENT: Khung tạo bài viết mới ---
  Widget _buildCreatePostCard(Color surfaceColor, Color textColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Hôm nay bạn có gì vui?',
                    hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPostActionButton(Icons.photo_library_rounded, 'Hình ảnh', Colors.green),
              _buildPostActionButton(Icons.videocam_rounded, 'Video', Colors.redAccent),
              _buildPostActionButton(Icons.music_note_rounded, 'Âm nhạc', Colors.orange),
              _buildPostActionButton(Icons.gif_box_rounded, 'GIF', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostActionButton(IconData icon, String label, Color color) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
  }

  // --- COMPONENT: Thẻ bài viết (Post) ---
  Widget _buildPostCard(Post post, Color surfaceColor, Color textColor, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header của bài viết (Avatar + Tên + Giờ)
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(post.userAvatar)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    Text(post.timeAgo, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 13)),
                  ],
                ),
              ),
              IconButton(icon: Icon(Icons.more_horiz_rounded, color: textColor.withValues(alpha: 0.5)), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 16),

          // Nội dung Text
          if (post.content != null && post.content!.isNotEmpty) ...[
            Text(post.content!, style: TextStyle(fontSize: 15, color: textColor, height: 1.4)),
            const SizedBox(height: 16),
          ],

          // Media (Hình ảnh / Video / Nhạc)
          if (post.mediaType != 'none') _buildMediaContent(post, primaryColor),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Nút tương tác
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInteractionButton(
                icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: post.isLiked ? Colors.redAccent : textColor.withValues(alpha: 0.6),
                label: '${post.likes} Thích',
                onTap: () => _controller.toggleLike(post.id),
              ),
              _buildInteractionButton(
                icon: Icons.chat_bubble_outline_rounded,
                color: textColor.withValues(alpha: 0.6),
                label: '${post.comments} Bình luận',
                onTap: () {},
              ),
              _buildInteractionButton(
                icon: Icons.share_rounded,
                color: textColor.withValues(alpha: 0.6),
                label: 'Chia sẻ',
                onTap: () {},
              ),
            ],
          )
        ],
      ),
    );
  }

  // Khung render phương tiện (Media)
  Widget _buildMediaContent(Post post, Color primaryColor) {
    if (post.mediaType == 'image' || post.mediaType == 'gif') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(post.mediaUrl!, width: double.infinity, fit: BoxFit.cover),
      );
    } else if (post.mediaType == 'music') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Message / Music', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Container(width: 200, height: 4, decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInteractionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}