// ignore_file: file_names
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  final _storage = const FlutterSecureStorage();

  final ValueNotifier<Map<String, dynamic>?> incomingMessage = ValueNotifier(null);

  Future<void> startConnection() async {
    // Nếu đang connect rồi thì thôi
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    String? token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          "http://localhost:5034/chatHub", 
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on("ReceiveMessage", _handleIncomingMessage);

    try {
      await _hubConnection?.start();
      debugPrint("🔥 SignalR ĐÃ KẾT NỐI THÀNH CÔNG!");
    } catch (e) {
      debugPrint("❌ SignalR LỖI KẾT NỐI: $e");
    }
  }

  // ==========================================
  // 🎯 VŨ KHÍ MỚI: HÀM NGẮT KẾT NỐI KHI ĐĂNG XUẤT
  // ==========================================
  Future<void> stopConnection() async {
    if (_hubConnection != null) {
      await _hubConnection?.stop();
      _hubConnection = null;
      debugPrint("🛑 SignalR đã ngắt kết nối hoàn toàn!");
    }
  }

  Future<void> sendMessage(String conversationId, String content, String type) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke("SendMessage", args: [conversationId, content, type]);
    } else {
      throw Exception("SignalR chưa được kết nối!");
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

      debugPrint("📩 SignalR nhận message: $data");
      incomingMessage.value = data;
    } else {
      debugPrint("❌ SignalR data không phải Map: $raw");
    }
  }

  Future<void> joinConversation(String conversationId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke("JoinConversation", args: [conversationId]);
    }
  }
}