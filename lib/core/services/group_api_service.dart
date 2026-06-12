import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GroupApiService {
  static const String baseUrl = 'http://localhost:5034/api/Conversations';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Tạo nhóm chat mới và trả về conversationId
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
        'memberIds': memberIds,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['conversationId'];
    }

    throw Exception('Lỗi tạo nhóm: ${jsonDecode(response.body)['message']}');
  }

  // Thêm thành viên mới vào nhóm chat
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

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(jsonDecode(response.body)['message'] ?? 'Lỗi thêm thành viên');
  }

  // Mời một thành viên ra khỏi nhóm chat
  Future<bool> kickMember(String conversationId, String userIdToKick) async {
    final token = await _storage.read(key: 'jwt_token');

    final response = await http.delete(
      Uri.parse('$baseUrl/$conversationId/members/$userIdToKick'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(jsonDecode(response.body)['message'] ?? 'Lỗi kick thành viên');
  }
}