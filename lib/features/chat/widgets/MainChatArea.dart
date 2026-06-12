// ignore_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../profile/FriendProfileScreen.dart';
import '../../call/CallScreen.dart';
import 'chat_message.dart'; 
import 'HoverableMessageBubble.dart';
import 'ChatInputArea.dart'; 
import '../../contacts/ContactsController.dart'; 
import '../widgets/add_member_dialog.dart';
import '../../auth/AuthController.dart';
import '../../../core/services/signalr_service.dart'; 
import '../../../core/services/local_db_service.dart'; 
import '../../../core/services/group_api_service.dart'; 

class MainChatArea extends StatefulWidget {
  final String chatId; // Đối với nhóm, đây là conversationId
  final String chatName;
  final String chatAvatar;
  final String chatCover;
  final String chatBio;
  final String relationStatus; 
  final bool autoStartVoiceCall;
  final bool autoStartVideoCall;
  final bool isGroup; 

  const MainChatArea({
    super.key, 
    required this.chatId,
    required this.chatName,
    required this.chatAvatar,
    this.chatCover = '',
    this.chatBio = '',
    this.relationStatus = 'friend',
    this.autoStartVoiceCall = false,
    this.autoStartVideoCall = false,
    this.isGroup = false, 
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

  ChatMessage? _replyingToMessage;
  bool _isOnline = false;

  List<dynamic> _groupMembers = [];
  String _myRole = 'member';

  @override
  void initState() {
    super.initState();
    _cachedAvatar = _getSmartAvatar(widget.chatAvatar, widget.chatId);
    _initializeChat();
    
    if (!widget.isGroup) {
      _checkInitialOnlineStatus();
      _signalR.userStatusSignal.addListener(_onUserStatusChanged);
    }
    _signalR.incomingMessage.addListener(_onNewMessageReceived);
  }

  @override
  void didUpdateWidget(MainChatArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _cachedAvatar = _getSmartAvatar(widget.chatAvatar, widget.chatId);
      _replyingToMessage = null; 
      
      if (!widget.isGroup) {
        _isOnline = false;
        _checkInitialOnlineStatus();
      }
      
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
    if (!widget.isGroup) {
      _signalR.userStatusSignal.removeListener(_onUserStatusChanged);
    }
    super.dispose();
  }
  
  Future<void> _checkInitialOnlineStatus() async {
    final online = await _signalR.checkUserOnline(widget.chatId);
    if (mounted) setState(() => _isOnline = online);
  }

  void _onUserStatusChanged() {
    final status = _signalR.userStatusSignal.value;
    if (status == null) return;

    if (status['userId'].toString().toLowerCase() == widget.chatId.toLowerCase()) {
      if (mounted) setState(() => _isOnline = status['isOnline']);
    }
  }

  Future<void> _getCurrentUser() async {
    _currentUserId = await AuthController().getCurrentUserId();
  }

  String _formatTime(dynamic createdAtStr) {
    if (createdAtStr == null) return 'Đang gửi...';
    try {
      final localTime = DateTime.parse(createdAtStr.toString()).toLocal();
      final hour = localTime.hour.toString().padLeft(2, '0');
      final minute = localTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return 'Vừa xong'; 
    }
  }

  Future<void> _fetchGroupMembers() async {
    if (!widget.isGroup || _currentConversationId == null) return;
    try {
      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      final res = await http.get(
        Uri.parse('http://localhost:5034/api/Conversations/$_currentConversationId/members'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      if (res.statusCode == 200) {
        final members = jsonDecode(res.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _groupMembers = members;
            final me = members.firstWhere(
              (m) => m['userId'].toString().toLowerCase() == _currentUserId.toLowerCase(), 
              orElse: () => null
            );
            if (me != null) _myRole = me['role'] ?? 'member';
          });
        }
      }
    } catch (e) { debugPrint("Lỗi tải thành viên nhóm: $e"); }
  }

  Future<void> _initializeChat() async {
    if (_isInitializing) return;
    _isInitializing = true;
    final initializingChatId = widget.chatId;

    try {
      await _signalR.startConnection();
      await _getCurrentUser();
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');

      if (widget.isGroup) {
        _currentConversationId = widget.chatId;
      } else {
        final response = await http.post(
          Uri.parse('http://localhost:5034/api/Conversations/get-or-create'),
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer $token' },
          body: jsonEncode({'friendId': widget.chatId}),
        );
        if (response.statusCode != 200) return;
        final data = jsonDecode(response.body);
        _currentConversationId = data['conversationId']?.toString();
      }

      if (_currentConversationId == null || _currentConversationId!.isEmpty) return;

      await _signalR.joinConversation(_currentConversationId!);
      
      if (widget.isGroup) await _fetchGroupMembers();

      final localDb = LocalDbService();
      final localMsgs = await localDb.getMessages(_currentConversationId!);
      
      if (localMsgs.isNotEmpty && mounted && initializingChatId == widget.chatId) {
        setState(() {
          messages = localMsgs.map((m) {
            final isMyMessage = m['senderId'].toString().toLowerCase() == _currentUserId.toLowerCase();
            return ChatMessage(
              text: m['content'] ?? '',
              type: m['type'] ?? 'text',
              isMe: isMyMessage,
              time: _formatTime(m['createdAt']), 
              replyToText: m['replyToText'], 
            );
          }).toList();
        });
        _scrollToBottom();
      }

      String? lastTime = await localDb.getLastMessageTime(_currentConversationId!);
      String apiUrl = 'http://localhost:5034/api/Conversations/$_currentConversationId/messages';
      
      if (lastTime != null) {
        apiUrl += '?since=${Uri.encodeComponent(lastTime)}';
      }

      final historyRes = await http.get(
        Uri.parse(apiUrl),
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer $token' },
      );

      if (!mounted || initializingChatId != widget.chatId) return;

      if (historyRes.statusCode == 200) {
        final List<dynamic> newServerData = jsonDecode(historyRes.body);

        if (newServerData.isNotEmpty) {
          final validMessages = newServerData.where((m) {
            final type = (m['type'] ?? 'text').toString();
            return !(type == 'offer_video' || type == 'offer_voice' || type == 'answer' || type == 'ice' || type == 'end' || type.startsWith('webrtc_'));
          }).toList();

          for (var m in validMessages) {
            String? historyReplyText;
            final metaRaw = m['metadata'] ?? m['Metadata']; 
            if (metaRaw != null) {
              try {
                final meta = metaRaw is Map ? metaRaw : jsonDecode(metaRaw.toString());
                historyReplyText = meta['replyToText']?.toString();
              } catch (_) {}
            }
            await localDb.saveMessage(m, _currentConversationId!, historyReplyText);
          }

          final updatedLocalMsgs = await localDb.getMessages(_currentConversationId!);
          if (mounted && initializingChatId == widget.chatId) {
            setState(() {
              messages = updatedLocalMsgs.map((m) {
                final isMyMessage = m['senderId'].toString().toLowerCase() == _currentUserId.toLowerCase();
                return ChatMessage(
                  text: m['content'] ?? '',
                  type: m['type'] ?? 'text',
                  isMe: isMyMessage,
                  time: _formatTime(m['createdAt']), 
                  replyToText: m['replyToText'], 
                );
              }).toList();
            });
            _scrollToBottom();
          }
        }

        if (widget.autoStartVoiceCall) {
          _openCallScreen(isVideo: false);
        } else if (widget.autoStartVideoCall) {
          _openCallScreen(isVideo: true);
        }
      }
    } catch (e) {
      debugPrint("Lỗi kết nối khi khởi tạo chat: $e");
    } finally {
      _isInitializing = false;
    }
  }

  void _onNewMessageReceived() async {
    final msg = _signalR.incomingMessage.value;
    if (msg == null) return;

    final msgConversationId = (msg['conversationId'] ?? msg['ConversationId'])?.toString().toLowerCase();
    final currentConversationId = _currentConversationId?.toLowerCase();

    if (msgConversationId != currentConversationId) return;

    final type = (msg['type'] ?? msg['Type'] ?? 'text').toString();
    final senderId = (msg['senderId'] ?? msg['SenderId'])?.toString().toLowerCase();
    final isMyMessage = senderId == _currentUserId.toLowerCase();
    final content = (msg['content'] ?? msg['Content'] ?? '').toString();

    if (type == 'offer_video' || type == 'offer_voice' || type == 'answer' || type == 'ice' || type == 'end' || type.startsWith('webrtc_')) return;

    String? incomingReplyText;
    final metaRaw = msg['metadata'] ?? msg['Metadata'];
    if (metaRaw != null && metaRaw.toString().isNotEmpty) {
      try {
        final meta = jsonDecode(metaRaw.toString());
        incomingReplyText = meta['replyToText']?.toString();
      } catch (_) {}
    }

    await LocalDbService().saveMessage(msg, _currentConversationId!, incomingReplyText);

    if (mounted) {
      setState(() {
        final timeString = msg['createdAt'] ?? msg['CreatedAt'];

        if (isMyMessage) {
          messages.removeWhere((m) => m.time == 'Đang gửi...' && m.text == content);
        }

        messages.add(ChatMessage(
          text: content, 
          type: type,
          isMe: isMyMessage, 
          time: _formatTime(timeString),
          replyToText: incomingReplyText, 
        ));
      });
    }
    _scrollToBottom();
  }

  void _handleSend(String text, {String type = 'text'}) async {
    if (_currentConversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang kết nối phòng, vui lòng thử lại!')));
      return;
    }

    String? repliedText = _replyingToMessage?.text;
    String? metadataJsonString;
    if (repliedText != null) {
      metadataJsonString = jsonEncode({'replyToText': repliedText});
    }

    if (_replyingToMessage != null) {
      setState(() { _replyingToMessage = null; });
    }

    setState(() {
      messages.add(ChatMessage(
        text: text, 
        type: type,
        isMe: true, 
        time: 'Đang gửi...', 
        replyToText: repliedText, 
      ));
    });
    _scrollToBottom();

    try {
      await _signalR.sendMessage(_currentConversationId!, text, type, metadata: metadataJsonString); 
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.removeWhere((m) => m.time == 'Đang gửi...' && m.text == text);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể gửi tin nhắn!')));
      }
    }
  }

  void _openCallScreen({required bool isVideo}) {
    if (_currentConversationId == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(
      isVideoCall: isVideo,
      userName: widget.chatName,
      avatarUrl: widget.chatAvatar,
      conversationId: _currentConversationId!,
      isCaller: true,
      onCallEndedLog: (callType, content) => _handleSend(content, type: callType),
    )));
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
    return NetworkImage(widget.isGroup ? 'https://ui-avatars.com/api/?name=${widget.chatName}&background=random' : 'https://i.pravatar.cc/150?u=$userId');
  }

  void _openUserProfile() {
    if (widget.isGroup) return; 
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
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              return HoverableMessageBubble(
                                key: ValueKey('${message.text}_${message.time}_$index'),
                                message: message,
                                onReply: (msg) {
                                  setState(() { _replyingToMessage = msg; });
                                },
                                onReact: (emoji) {
                                  setState(() {
                                    if (messages[index].reactions.containsKey(emoji)) {
                                      messages[index].reactions[emoji] = messages[index].reactions[emoji]! + 1;
                                    } else {
                                      messages[index].reactions[emoji] = 1;
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                ),
                
                if (_replyingToMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(color: surfaceColor, border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
                    child: Row(
                      children: [
                        Icon(Icons.reply_rounded, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _replyingToMessage!.isMe ? 'Trả lời chính mình' : 'Trả lời ${widget.chatName}',
                                style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(_replyingToMessage!.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() => _replyingToMessage = null),
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(), color: textColor.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),

                ChatInputArea(
                  onSendMessage: (text) => _handleSend(text, type: 'text'),
                  onSendGif: (url) => _handleSend(url, type: 'image'),
                  onSendVoice: (duration) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã ghi âm ($duration giây).'))),
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
          MouseRegion(
            cursor: SystemMouseCursors.click, 
            child: GestureDetector(
              onTap: _openUserProfile, 
              child: Stack(
                children: [
                  CircleAvatar(radius: 22, backgroundImage: _cachedAvatar), 
                  if (!widget.isGroup)
                    Positioned(
                      right: 0, bottom: 0, 
                      child: Container(
                        width: 12, height: 12, 
                        decoration: BoxDecoration(
                          color: _isOnline ? Colors.green : Colors.grey.shade400, 
                          shape: BoxShape.circle, 
                          border: Border.all(color: surfaceColor, width: 2)
                        )
                      )
                    )
                ]
              )
            )
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click, 
                  child: GestureDetector(
                    onTap: _openUserProfile, 
                    child: Text(widget.chatName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))
                  )
                ), 
                if (widget.isGroup)
                  Text('${_groupMembers.length} thành viên', style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.5)))
                else
                  Text(_isOnline ? 'Đang hoạt động' : 'Ngoại tuyến', style: TextStyle(fontSize: 13, color: _isOnline ? primaryColor : Colors.grey))
              ]
            )
          ),
          IconButton(icon: Icon(Icons.call_outlined, color: primaryColor), onPressed: () => _openCallScreen(isVideo: false)),
          IconButton(icon: Icon(Icons.videocam_outlined, color: primaryColor), onPressed: () => _openCallScreen(isVideo: true)),
          IconButton(icon: Icon(_showInfoPanel ? Icons.info_rounded : Icons.info_outline, color: _showInfoPanel ? primaryColor : textColor.withValues(alpha: 0.6)), onPressed: () => setState(() => _showInfoPanel = !_showInfoPanel)),
        ],
      ),
    );
  }

  Widget _buildRightInfoPanelWrapper(Color textColor, Color primaryColor, Color surfaceColor) {
    return Container(key: const ValueKey('panel'), width: 320, decoration: BoxDecoration(color: surfaceColor, border: Border(left: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))), child: _buildRightInfoPanel(textColor, primaryColor));
  }

  Widget _buildRightInfoPanel(Color textColor, Color primaryColor) {
    if (widget.isGroup) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32), CircleAvatar(radius: 48, backgroundImage: _cachedAvatar), const SizedBox(height: 16),
            Text(widget.chatName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            Text('${_groupMembers.length} thành viên', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                // 🎯 ĐÃ GẮN POPUP VÀO NÚT THÊM BẠN
                _buildInfoActionBtn(Icons.group_add_rounded, 'Thêm bạn', textColor, onTap: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => AddMemberDialog(
                      controller: _contactController, 
                      conversationId: _currentConversationId!
                    ),
                  );
                  if (result == true) {
                    await _fetchGroupMembers(); 
                  }
                }), 
                const SizedBox(width: 24), 
                _buildInfoActionBtn(Icons.notifications_off_outlined, 'Tắt âm', textColor),
              ]
            ),
            const SizedBox(height: 24), Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('Thành viên nhóm', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _groupMembers.length,
              itemBuilder: (context, index) {
                final member = _groupMembers[index];
                final isMe = member['userId'].toString().toLowerCase() == _currentUserId.toLowerCase();
                final isAdmin = member['role'] == 'admin';

                return ListTile(
                  leading: CircleAvatar(backgroundImage: _getSmartAvatar(member['avatarUrl'], member['userId'])),
                  title: Text(isMe ? 'Bạn' : member['fullName']),
                  subtitle: isAdmin ? const Text('Trưởng nhóm', style: TextStyle(color: Colors.green, fontSize: 12)) : null,
                  trailing: (_myRole == 'admin' && !isMe) 
                    ? IconButton(
                        icon: const Icon(Icons.person_remove_rounded, color: Colors.red, size: 20),
                        tooltip: 'Mời khỏi nhóm',
                        onPressed: () async {
                          try {
                            await GroupApiService().kickMember(_currentConversationId!, member['userId']);
                            await _fetchGroupMembers(); 
                            if(context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã mời thành viên ra khỏi nhóm')));
                            }
                          } catch (e) {
                            if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                      ) 
                    : null,
                );
              }
            )
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32), CircleAvatar(radius: 48, backgroundImage: _cachedAvatar), const SizedBox(height: 16),
          Text(widget.chatName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          Text(
            _isOnline ? 'Đang hoạt động' : 'Ngoại tuyến', 
            style: TextStyle(fontSize: 14, color: _isOnline ? primaryColor : textColor.withValues(alpha: 0.5))
          ),
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