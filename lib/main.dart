import 'package:flutter/material.dart';

void main() {
  runApp(const ChatAppDesktop());
}

class ChatAppDesktop extends StatelessWidget {
  const ChatAppDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro Chat Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0068FF), // Màu xanh đặc trưng của Zalo/Facebook
        scaffoldBackgroundColor: Colors.white,
        dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB), space: 1, thickness: 1),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. App Sidebar Navigation
          _buildNavigationRail(),
          const VerticalDivider(width: 1),
          
          // 2. Chat List Panel (Fixed width)
          SizedBox(
            width: 320,
            child: _buildChatListPanel(),
          ),
          const VerticalDivider(width: 1),
          
          // 3. Main Chat Area (Takes remaining space)
          Expanded(
            child: _buildMainChatArea(),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT 1: TThanh điều hướng bên trái ---
  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      labelType: NavigationRailLabelType.none,
      leading: const Padding(
        padding: EdgeInsets.only(bottom: 20.0, top: 10.0),
        child: CircleAvatar(
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          radius: 20,
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: Text('Tin nhắn'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.contacts_outlined),
          selectedIcon: Icon(Icons.contacts),
          label: Text('Danh bạ'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Cài đặt'),
        ),
      ],
    );
  }

  // --- COMPONENT 2: Danh sách đoạn chat ---
  Widget _buildChatListPanel() {
    return Column(
      children: [
        // Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const Divider(),
        // Danh sách chat
        Expanded(
          child: ListView.builder(
            itemCount: 15,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${index + 20}'),
                  radius: 24,
                ),
                title: Text(
                  'Người dùng ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  index % 3 == 0 ? 'Bạn: Chào cậu nha!' : 'Gửi cho tôi file báo cáo nhé.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '10:${index + 10} AM',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    if (index % 2 == 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  // Xử lý chọn chat
                },
                selectedTileColor: Colors.blue.withValues(alpha: 0.05),
                selected: index == 0, // Mock: Đoạn chat đầu tiên đang được chọn
              );
            },
          ),
        ),
      ],
    );
  }

  // --- COMPONENT 3: Khu vực Chat chính ---
  Widget _buildMainChatArea() {
    return Container(
      color: const Color(0xFFF4F5F7), // Màu nền nhẹ cho khu vực chat
      child: Column(
        children: [
          // Header: Thông tin người đang chat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=20'),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Người dùng 1',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Vừa mới truy cập',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.blue), onPressed: () {}),
                IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.blue), onPressed: () {}),
                IconButton(icon: const Icon(Icons.info_outline, color: Colors.grey), onPressed: () {}),
              ],
            ),
          ),
          
          // Body: Lịch sử tin nhắn
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildMessageBubble("Xin chào! Dự án tới đâu rồi bạn?", false),
                _buildMessageBubble("Mình đang setup giao diện Flutter Desktop.", true),
                _buildMessageBubble("Tuyệt vời, nhớ tối ưu cho cả Web và Mobile nhé. Nhìn giao diện chia cột rất chuyên nghiệp!", false),
                _buildMessageBubble("Chắc chắn rồi. Mình sẽ thiết kế clean architecture ngay từ đầu.", true),
              ],
            ),
          ),
          
          // Footer: Khung nhập tin nhắn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: () {}),
                IconButton(icon: const Icon(Icons.image_outlined, color: Colors.grey), onPressed: () {}),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn tới Người dùng 1...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey), onPressed: () {}),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hỗ trợ vẽ bong bóng tin nhắn
  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            if (!isMe)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}