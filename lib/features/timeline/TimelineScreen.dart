// ignore_file: file_names
import 'package:flutter/material.dart';
import 'TimelineController.dart';
// Import các widget đã làm để tái sử dụng
import '../chat/widgets/FullScreenImageViewer.dart';
import '../profile/FriendProfileScreen.dart';
// 🎯 IMPORT THÊM CONTACTS CONTROLLER
import '../contacts/ContactsController.dart'; 

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final TimelineController _controller = TimelineController();
  final ScrollController _scrollController = ScrollController();
  
  // 🎯 KHAI BÁO CONTROLLER TẠI ĐÂY
  final ContactsController _contactController = ContactsController();

  @override
  void dispose() {
    _scrollController.dispose();
    _contactController.dispose(); // Nhớ giải phóng bộ nhớ
    super.dispose();
  }

  // --- HÀM MỞ MÀN HÌNH HỒ SƠ (ĐÃ SỬA THÊM THAM SỐ) ---
  void _openUserProfile(String userName, String avatarUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendProfileScreen(
          userId: 'mock_timeline_id', // ID tạm thời cho Timeline giả lập
          userName: userName,
          avatarUrl: avatarUrl,
          bio: 'Hoạt động năng nổ trên Timeline 🌟',
          initialIsFriend: true, 
          contactController: _contactController, // Truyền Controller vào
        ),
      ),
    );
  }

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
          color: bgColor, 
          child: Column(
            children: [
              // ==========================================
              // HEADER: TIÊU ĐỀ + TÌM KIẾM + BỘ LỌC
              // ==========================================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                    const Spacer(),
                    
                    // Ô Tìm Kiếm bài viết
                    Container(
                      width: 280,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bài viết...',
                          hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: textColor.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Nút Lọc (Filter)
                    IconButton(
                      icon: const Icon(Icons.tune_rounded),
                      color: textColor.withValues(alpha: 0.7),
                      tooltip: 'Bộ lọc bảng tin',
                      onPressed: () {
                        // TODO: Hiện menu chọn Mới nhất / Phổ biến
                      },
                    ),
                  ],
                ),
              ),

              // ==========================================
              // BẢNG TIN (FEED) KÈM SCROLLBAR
              // ==========================================
              Expanded(
                child: RawScrollbar(
                  controller: _scrollController,
                  thumbColor: textColor.withValues(alpha: 0.2),
                  radius: const Radius.circular(8),
                  thickness: 6,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680), // Giới hạn độ rộng chuẩn cho bài viết
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Hôm nay bạn có gì vui?',
                      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPostActionButton(Icons.photo_library_rounded, 'Hình ảnh', Colors.green),
              _buildPostActionButton(Icons.videocam_rounded, 'Video', Colors.redAccent),
              _buildPostActionButton(Icons.music_note_rounded, 'Âm nhạc', Colors.orange),
              // Nút Đăng bài nổi bật
              FilledButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Đăng'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostActionButton(IconData icon, String label, Color color) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color, size: 22),
      label: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  // --- COMPONENT: Thẻ bài viết (Post) ---
  Widget _buildPostCard(dynamic post, Color surfaceColor, Color textColor, Color primaryColor) {
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
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _openUserProfile(post.userName, post.userAvatar),
                  child: CircleAvatar(radius: 22, backgroundImage: NetworkImage(post.userAvatar)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _openUserProfile(post.userName, post.userAvatar),
                        child: Text(post.userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      ),
                    ),
                    Row(
                      children: [
                        Text(post.timeAgo, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 13)),
                        const SizedBox(width: 4),
                        Icon(Icons.public_rounded, size: 14, color: textColor.withValues(alpha: 0.5)),
                      ],
                    ),
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

          // Dải đếm Like & Comment nhỏ
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16),
                const SizedBox(width: 4),
                Text('${post.likes}', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13)),
                const Spacer(),
                Text('${post.comments} bình luận', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13)),
              ],
            ),
          ),
          
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Nút tương tác
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInteractionButton(
                icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: post.isLiked ? Colors.redAccent : textColor.withValues(alpha: 0.6),
                label: 'Thích',
                onTap: () => _controller.toggleLike(post.id),
              ),
              _buildInteractionButton(
                icon: Icons.chat_bubble_outline_rounded,
                color: textColor.withValues(alpha: 0.6),
                label: 'Bình luận',
                onTap: () {}, 
              ),
              _buildInteractionButton(
                icon: Icons.share_rounded,
                color: textColor.withValues(alpha: 0.6),
                label: 'Chia sẻ',
                onTap: () {},
              ),
            ],
          ),

          // Ô nhập Bình luận nhanh
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')), 
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Viết bình luận...',
                            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(bottom: 12),
                          ),
                        ),
                      ),
                      Icon(Icons.sentiment_satisfied_alt_rounded, size: 20, color: textColor.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Icon(Icons.camera_alt_outlined, size: 20, color: textColor.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(dynamic post, Color primaryColor) {
    if (post.mediaType == 'image' || post.mediaType == 'gif') {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false, 
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, animation, _) {
                  return FadeTransition(
                    opacity: animation,
                    child: FullScreenImageViewer(
                      imageUrl: post.mediaUrl!,
                      heroTag: 'post_image_${post.id}',
                    ),
                  );
                },
              ),
            );
          },
          child: Hero(
            tag: 'post_image_${post.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(post.mediaUrl!, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
        ),
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}