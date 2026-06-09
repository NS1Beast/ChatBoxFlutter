// ignore_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../profile/FriendProfileScreen.dart';
import '../../call/CallScreen.dart';
import '../models/chat_message.dart';
import 'HoverableMessageBubble.dart';
import 'ChatInputArea.dart'; 
import '../../contacts/ContactsController.dart'; 
import '../../auth/AuthController.dart';
import '../../../core/services/signalr_service.dart'; 

class MainChatArea extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String chatAvatar;
  final String chatCover;
  final String chatBio;
  final String relationStatus; 

  const MainChatArea({
    super.key, 
    required this.chatId,
    required this.chatName,
    required this.chatAvatar,
    this.chatCover = '',
    this.chatBio = '',
    this.relationStatus = 'friend',
  });

  @override
  State<MainChatArea> createState() => _MainChatAreaState();
}

class _MainChatAreaState extends State<MainChatArea> {
  final ScrollController _scrollController = ScrollController();
  bool _showInfoPanel = false;
  final ContactsController _contactController = ContactsController();
  List<ChatMessage> messages = [];
  late ImageProvider _cachedAvatar;

  final SignalRService _signalR = SignalRService();
  String? _currentConversationId;
  String _currentUserId = "guest";
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _cachedAvatar = _getSmartAvatar(widget.chatAvatar, widget.chatId);
    _initializeChat();
    _signalR.incomingMessage.addListener(_onNewMessageReceived);
  }

  // 🎯 ĐÃ FIX: Không gọi API lặp lại nếu chỉ đổi Avatar
  @override
  void didUpdateWidget(MainChatArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _cachedAvatar = _getSmartAvatar(widget.chatAvatar, widget.chatId);
      _initializeChat();
    } else if (oldWidget.chatAvatar != widget.chatAvatar) {
      _cachedAvatar = _getSmartAvatar(widget.chatAvatar, widget.chatId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _contactController.dispose(); 
    _signalR.incomingMessage.removeListener(_onNewMessageReceived);
    super.dispose();
  }
  
  Future<void> _getCurrentUser() async {
    _currentUserId = await AuthController().getCurrentUserId();
  }

  // 🎯 ĐÃ FIX: Log rõ ràng, không clear message nếu lỗi API
  Future<void> _initializeChat() async {
    if (_isInitializing) return;
    _isInitializing = true;

    final initializingChatId = widget.chatId;

    try {
      await _signalR.startConnection();
      await _getCurrentUser();

      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');

      final response = await http.post(
        Uri.parse('http://localhost:5034/api/Conversations/get-or-create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'friendId': widget.chatId}),
      );

      if (response.statusCode != 200) {
        debugPrint("Lỗi tạo phòng chat: status=${response.statusCode}, body=${response.body}");
        return;
      }

      final data = jsonDecode(response.body);
      final conversationId = data['conversationId']?.toString();

      if (conversationId == null || conversationId.isEmpty) {
        debugPrint("conversationId null hoặc rỗng");
        return;
      }

      _currentConversationId = conversationId;
      await _signalR.joinConversation(_currentConversationId!);
      
      final historyRes = await http.get(
        Uri.parse('http://localhost:5034/api/Conversations/$_currentConversationId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("History status=${historyRes.statusCode}, body=${historyRes.body}");

      if (!mounted || initializingChatId != widget.chatId) return;

      if (historyRes.statusCode == 200) {
        final List<dynamic> historyData = jsonDecode(historyRes.body);

        final loadedMessages = historyData.map((m) {
          final senderId = m['senderId']?.toString().toLowerCase() ?? '';
          final isMyMessage = senderId == _currentUserId.toLowerCase();

          return ChatMessage(
            text: m['content'] ?? '',
            isMe: isMyMessage,
            time: 'Đã gửi',
            type: m['type'] ?? 'text',
          );
        }).toList();

        setState(() {
          messages = loadedMessages;
        });

        _scrollToBottom();
      } else {
        debugPrint("Không load được history, giữ nguyên messages hiện tại. status=${historyRes.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi kết nối khi khởi tạo chat: $e");
    } finally {
      _isInitializing = false;
    }
  }

  // 🎯 ĐÃ FIX: Chống lỗi lệch chữ Hoa/Thường từ Backend C#
  void _onNewMessageReceived() {
    final msg = _signalR.incomingMessage.value;
    if (msg == null) return;

    final msgConversationId = (msg['conversationId'] ?? msg['ConversationId'])?.toString().toLowerCase();
    final currentConversationId = _currentConversationId?.toLowerCase();

    if (msgConversationId != currentConversationId) {
      debugPrint("Bỏ qua message vì khác phòng. msg=$msgConversationId, current=$currentConversationId");
      return;
    }

    if (mounted) {
      setState(() {
        final senderId = (msg['senderId'] ?? msg['SenderId'])?.toString().toLowerCase();
        final content = (msg['content'] ?? msg['Content'] ?? '').toString();
        final type = (msg['type'] ?? msg['Type'] ?? 'text').toString();

        final isMyMessage = senderId == _currentUserId.toLowerCase();

        if (isMyMessage) {
          messages.removeWhere((m) => m.time == 'Đang gửi...' && m.text == content);
        }

        messages.add(ChatMessage(text: content, isMe: isMyMessage, time: 'Vừa xong', type: type));
      });
    }
    _scrollToBottom();
  }

  void _handleSend(String text, {String type = 'text'}) async {
    if (_currentConversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang kết nối phòng, vui lòng thử lại!')));
      return;
    }

    setState(() {
      messages.add(ChatMessage(text: text, isMe: true, time: 'Đang gửi...', type: type));
    });
    _scrollToBottom();

    try {
      await _signalR.sendMessage(_currentConversationId!, text, type);
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.removeWhere((m) => m.time == 'Đang gửi...' && m.text == text);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể gửi tin nhắn!')));
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  ImageProvider _getSmartAvatar(String? avatarUrl, String userId) {
    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.toLowerCase() != 'null') {
      if (avatarUrl.startsWith('data:image')) {
        final split = avatarUrl.split(',');
        if (split.length == 2) {
          try { return MemoryImage(base64Decode(split[1])); } catch (e) { debugPrint("Lỗi Base64: $e"); }
        }
      } else {
        return NetworkImage(avatarUrl);
      }
    }
    return NetworkImage('https://i.pravatar.cc/150?u=$userId');
  }

  void _openUserProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
      userId: widget.chatId, userName: widget.chatName, avatarUrl: widget.chatAvatar, coverImageUrl: widget.chatCover, bio: widget.chatBio, initialRelationStatus: widget.relationStatus, contactController: _contactController, 
    )));
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
          Expanded(
            child: Column(
              children: [
                _buildHeader(surfaceColor, textColor, primaryColor),
                Expanded(
                  child: messages.isEmpty 
                    ? _buildEmptyChatState(textColor) 
                    : RepaintBoundary(
                        child: RawScrollbar(
                          controller: _scrollController,
                          thumbColor: textColor.withValues(alpha: 0.2),
                          radius: const Radius.circular(8),
                          thickness: 6,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            itemCount: messages.length,
                            itemBuilder: (context, index) => HoverableMessageBubble(message: messages[index]),
                          ),
                        ),
                      ),
                ),
                ChatInputArea(
                  onSendMessage: (text) => _handleSend(text, type: 'text'),
                  onSendGif: (url) => _handleSend(url, type: 'image'),
                  onSendVoice: (duration) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã ghi âm ($duration giây). Chờ API Upload file!'))),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => SizeTransition(sizeFactor: animation, axis: Axis.horizontal, axisAlignment: -1.0, child: child),
            child: _showInfoPanel ? _buildRightInfoPanelWrapper(textColor, primaryColor, surfaceColor) : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Chưa có tin nhắn nào.\nHãy gửi lời chào đến ${widget.chatName}!', textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 15)),
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
          MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: _openUserProfile, child: Stack(children: [CircleAvatar(radius: 22, backgroundImage: _cachedAvatar), Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: surfaceColor, width: 2))))]))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: _openUserProfile, child: Text(widget.chatName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)))), Text('Đang hoạt động', style: TextStyle(fontSize: 13, color: primaryColor))])),
          IconButton(icon: Icon(Icons.call_outlined, color: primaryColor), onPressed: () => Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (context, animation, _) => CallScreen(isVideoCall: false, userName: widget.chatName, avatarUrl: widget.chatAvatar.isNotEmpty ? widget.chatAvatar : 'https://i.pravatar.cc/150?u=${widget.chatId}')))),
          IconButton(icon: Icon(Icons.videocam_outlined, color: primaryColor), onPressed: () => Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (context, animation, _) => CallScreen(isVideoCall: true, userName: widget.chatName, avatarUrl: widget.chatAvatar.isNotEmpty ? widget.chatAvatar : 'https://i.pravatar.cc/150?u=${widget.chatId}')))),
          IconButton(icon: Icon(_showInfoPanel ? Icons.info_rounded : Icons.info_outline, color: _showInfoPanel ? primaryColor : textColor.withValues(alpha: 0.6)), onPressed: () => setState(() => _showInfoPanel = !_showInfoPanel)),
        ],
      ),
    );
  }

  Widget _buildRightInfoPanelWrapper(Color textColor, Color primaryColor, Color surfaceColor) {
    return Container(key: const ValueKey('panel'), width: 320, decoration: BoxDecoration(color: surfaceColor, border: Border(left: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))), child: _buildRightInfoPanel(textColor, primaryColor));
  }

  Widget _buildRightInfoPanel(Color textColor, Color primaryColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32), CircleAvatar(radius: 48, backgroundImage: _cachedAvatar), const SizedBox(height: 16),
          Text(widget.chatName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          Text('Trực tuyến', style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildInfoActionBtn(Icons.person_outline, 'Hồ sơ', textColor, onTap: _openUserProfile), const SizedBox(width: 24), _buildInfoActionBtn(Icons.notifications_off_outlined, 'Tắt âm', textColor), const SizedBox(width: 24), _buildInfoActionBtn(Icons.search_rounded, 'Tìm kiếm', textColor)]),
          const SizedBox(height: 24), Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildInfoActionBtn(IconData icon, String label, Color textColor, {VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle), child: Icon(icon, color: textColor.withValues(alpha: 0.8))), const SizedBox(height: 8), Text(label, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7)))]));
  }
}