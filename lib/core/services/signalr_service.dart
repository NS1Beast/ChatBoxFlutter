// ignore_file: file_names

import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final ValueNotifier<Map<String, dynamic>?> incomingMessage =
      ValueNotifier<Map<String, dynamic>?>(null);

  final ValueNotifier<Map<String, dynamic>?> webRTCSignal =
      ValueNotifier<Map<String, dynamic>?>(null);

  final Set<String> _joinedConversations = <String>{};
  bool _isStarting = false;

  static const String baseUrl = 'http://localhost:5034';

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  Future<void> startConnection() async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;
    if (_hubConnection?.state == HubConnectionState.Connecting) return;
    if (_isStarting) return;

    _isStarting = true;

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        debugPrint('❌ SignalR không có jwt_token.');
        return;
      }

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            '$baseUrl/chatHub',
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection?.on('ReceiveMessage', _handleIncomingMessage);
      _hubConnection?.on('ReceiveWebRTCSignal', _handleWebRTCSignal);

      _hubConnection?.onclose(({error}) {
        debugPrint('🛑 SignalR đóng kết nối: $error');
      });

      _hubConnection?.onreconnecting(({error}) {
        debugPrint('🔄 SignalR đang reconnect: $error');
      });

      _hubConnection?.onreconnected(({connectionId}) async {
        debugPrint('✅ SignalR reconnect thành công: $connectionId');
        await _rejoinAllConversations();
      });

      await _hubConnection?.start();

      debugPrint('🔥 SignalR ĐÃ KẾT NỐI THÀNH CÔNG!');

      await _rejoinAllConversations();
    } catch (e) {
      debugPrint('❌ SignalR LỖI KẾT NỐI: $e');
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stopConnection() async {
    try {
      _joinedConversations.clear();

      if (_hubConnection != null) {
        await _hubConnection?.stop();
        _hubConnection = null;
      }

      debugPrint('🛑 SignalR đã ngắt kết nối hoàn toàn!');
    } catch (e) {
      debugPrint('❌ Lỗi stop SignalR: $e');
    }
  }

  Future<void> sendMessage(
    String conversationId,
    String content,
    String type, {
    String? metadata, 
  }) async {
    final normalizedConversationId = _normalizeConversationId(conversationId);

    if (!isConnected) {
      await startConnection();
    }

    if (!isConnected) {
      throw Exception('SignalR chưa được kết nối!');
    }

    await joinConversation(normalizedConversationId);

    try {
      // 🎯 ĐÃ FIX: Xử lý mảng args động để tránh lỗi String? không ném được vào List<Object>
      List<Object> args = [normalizedConversationId, content, type];
      if (metadata != null) {
        args.add(metadata);
      } else {
        // Nếu không có metadata thì quăng một chuỗi rỗng lên cho Backend nó tự xử
        args.add(""); 
      }

      await _hubConnection?.invoke(
        'SendMessage',
        args: args,
      );
    } catch (e) {
      debugPrint('❌ Lỗi gửi message SignalR: $e');
      rethrow;
    }
  }

  Future<void> sendCallSignal(
    String conversationId,
    String type,
    String content,
  ) async {
    final normalizedConversationId = _normalizeConversationId(conversationId);

    try {
      if (!isConnected) {
        await startConnection();
      }

      if (!isConnected) {
        debugPrint('❌ SignalR chưa kết nối, không thể gửi WebRTC signal [$type]');
        return;
      }

      await joinConversation(normalizedConversationId);

      await _hubConnection?.invoke(
        'SendWebRTCSignal',
        args: [
          normalizedConversationId,
          type,
          content,
        ],
      );

      if (type != 'ice') {
        debugPrint('📤 Đã gửi WebRTC signal: $type');
      }
    } catch (e) {
      debugPrint('❌ Lỗi gửi WebRTC signal [$type]: $e');
    }
  }

  Future<void> joinConversation(String conversationId) async {
    final normalizedConversationId = _normalizeConversationId(conversationId);

    if (_joinedConversations.contains(normalizedConversationId) && isConnected) {
      return;
    }

    try {
      if (!isConnected) {
        await startConnection();
      }

      if (!isConnected) {
        debugPrint('❌ Không thể join conversation vì SignalR chưa connect.');
        return;
      }

      await _hubConnection?.invoke(
        'JoinConversation',
        args: [normalizedConversationId],
      );

      _joinedConversations.add(normalizedConversationId);

      debugPrint('🚪 Đã join conversation: $normalizedConversationId');
    } catch (e) {
      debugPrint('❌ Lỗi join conversation [$normalizedConversationId]: $e');
    }
  }

  Future<void> _rejoinAllConversations() async {
    if (!isConnected || _joinedConversations.isEmpty) return;

    final rooms = List<String>.from(_joinedConversations);
    _joinedConversations.clear();

    for (final conversationId in rooms) {
      await joinConversation(conversationId);
    }
  }

  void _handleIncomingMessage(List<Object?>? args) {
    if (args == null || args.isEmpty || args[0] == null) return;

    final raw = args[0];

    if (raw is Map) {
      final data = <String, dynamic>{};

      raw.forEach((key, value) {
        data[key.toString()] = value;
      });

      debugPrint('📩 SignalR nhận message chat: $data');

      incomingMessage.value = {
        ...data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } else {
      debugPrint('❌ SignalR data không phải Map: $raw');
    }
  }

  void _handleWebRTCSignal(List<Object?>? args) {
    if (args == null || args.length < 3) {
      debugPrint('❌ WebRTC signal sai format: $args');
      return;
    }

    final conversationId = args[0]?.toString() ?? '';
    final type = args[1]?.toString() ?? '';
    final content = args[2]?.toString() ?? '';

    final callerName = (args.length > 3 && args[3] != null) ? args[3].toString() : 'Người gọi';
    final callerAvatar = (args.length > 4 && args[4] != null) ? args[4].toString() : '';

    if (conversationId.isEmpty || type.isEmpty) {
      debugPrint('❌ WebRTC signal thiếu conversationId/type: $args');
      return;
    }

    webRTCSignal.value = {
      'conversationId': _normalizeConversationId(conversationId),
      'type': type,
      'content': content,
      'callerName': callerName,     
      'callerAvatar': callerAvatar, 
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (type != 'ice') {
      debugPrint('📞 SignalR nhận WebRTC signal: $type từ $callerName');
    }
  }

  String _normalizeConversationId(String conversationId) {
    return conversationId.trim().toLowerCase();
  }
}