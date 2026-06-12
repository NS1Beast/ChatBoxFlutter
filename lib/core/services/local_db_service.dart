import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform; 
import 'package:flutter/foundation.dart'; // 🎯 Thêm kIsWeb để nhận diện Web
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit, databaseFactoryFfi; 
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Web không hỗ trợ SQLite trực tiếp.');
    }
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // 🔐 Tạo mật khẩu an toàn và cất vào Két sắt hệ điều hành
  Future<String> _getSecureDbPassword() async {
    const storage = FlutterSecureStorage();
    String? dbKey = await storage.read(key: 'local_db_secure_key');
    
    if (dbKey == null) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      dbKey = base64UrlEncode(values);
      await storage.write(key: 'local_db_secure_key', value: dbKey);
    }
    return dbKey;
  }

  Future<Database> _initDB() async {
    // 🎯 Kiểm tra an toàn: Đảm bảo không phải Web mới chạy Platform.is...
    final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    if (isDesktop) {
      sqfliteFfiInit();
    }

    final dbPath = isDesktop 
        ? await databaseFactoryFfi.getDatabasesPath() 
        : await getDatabasesPath();
        
    final path = join(dbPath, 'chat_local_secure.db');

    Future<void> onCreateLogic(Database db, int version) async {
      await db.execute('''
        CREATE TABLE LocalMessages (
          id TEXT PRIMARY KEY,
          conversationId TEXT,
          senderId TEXT,
          content TEXT,
          type TEXT,
          replyToText TEXT,
          createdAt TEXT
        )
      ''');
      await db.execute('CREATE INDEX idx_conv ON LocalMessages (conversationId)');
    }

    if (isDesktop) {
      // Dành cho Windows (Dùng FFI giả lập, không mật khẩu)
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: onCreateLogic,
        ),
      );
    } else {
      // Dành cho Android/iOS (Dùng SQLCipher có mã hóa 100%)
      final String dbPassword = await _getSecureDbPassword();
      return await openDatabase(
        path,
        version: 1,
        password: dbPassword,
        onCreate: onCreateLogic,
      );
    }
  }

  // ========================================================
  // 🎯 BỘ HÀM ĐÃ ĐƯỢC BỌC GIÁP CHỐNG CRASH TRÊN WEB
  // ========================================================
  Future<void> updateMessageContent(String messageId, String newContent, String newType) async {
    if (kIsWeb) return; 
    try {
      final db = await database;
      await db.update(
        'LocalMessages', // 🎯 Đã sửa: Phải dùng LocalMessages mới đúng tên bảng
        {'content': newContent, 'type': newType},
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint("Lỗi cập nhật local DB: $e");
    }
  }

  Future<void> deleteMessageLocal(String messageId) async {
    if (kIsWeb) return; 
    try {
      final db = await database;
      await db.delete(
        'LocalMessages', // 🎯 Đã sửa: Phải dùng LocalMessages mới đúng tên bảng
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint("Lỗi xóa local DB: $e");
    }
  }
  
  Future<void> saveMessage(Map<String, dynamic> msg, String conversationId, String? replyText) async {
    if (kIsWeb) return; 
    
    final db = await database;
    await db.insert('LocalMessages', {
      'id': msg['id'] ?? msg['Id'],
      'conversationId': conversationId.toLowerCase(),
      'senderId': msg['senderId'] ?? msg['SenderId'],
      'content': msg['content'] ?? msg['Content'],
      'type': msg['type'] ?? msg['Type'],
      'replyToText': replyText,
      'createdAt': msg['createdAt'] ?? msg['CreatedAt'],
    }, conflictAlgorithm: ConflictAlgorithm.replace); 
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    if (kIsWeb) return []; 

    final db = await database;
    return await db.query(
      'LocalMessages',
      where: 'conversationId = ?',
      whereArgs: [conversationId.toLowerCase()],
      orderBy: 'createdAt ASC', 
    );
  }

  Future<String?> getLastMessageTime(String conversationId) async {
    if (kIsWeb) return null; 

    final db = await database;
    final result = await db.query(
      'LocalMessages',
      columns: ['createdAt'],
      where: 'conversationId = ?',
      whereArgs: [conversationId.toLowerCase()],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return result.first['createdAt'] as String;
    return null;
  }
}