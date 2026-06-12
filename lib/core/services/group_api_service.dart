import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GroupApiService {
  static const String baseUrl = 'http://localhost:5034/api/Conversations';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 1. TẠO NHÓM MỚI
  Future<String?> createGroup(String groupName, List<String> memberIds) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/group'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'groupName': groupName,
        'memberIds': memberIds, // Truyền list UUID của bạn bè vào đây
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['conversationId']; // Trả về ID phòng để nhét vào MainChatArea
    } else {
      throw Exception('Lỗi tạo nhóm: ${jsonDecode(response.body)['message']}');
    }
  }

  // 2. THÊM THÀNH VIÊN
  Future<bool> addMembers(String conversationId, List<String> newMemberIds) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/$conversationId/members'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(newMemberIds),
    );

    if (response.statusCode == 200) return true;
    throw Exception(jsonDecode(response.body)['message'] ?? 'Lỗi thêm thành viên');
  }

  // 3. KICK THÀNH VIÊN (TRƯỞNG NHÓM)
  Future<bool> kickMember(String conversationId, String userIdToKick) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/$conversationId/members/$userIdToKick'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) return true;
    
    // Nếu bị mã 403 (Không phải admin) nó sẽ văng lỗi với dòng chữ "Chỉ trưởng nhóm..."
    throw Exception(jsonDecode(response.body)['message'] ?? 'Lỗi kick thành viên');
  }
}