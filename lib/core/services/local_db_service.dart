import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show sqfliteFfiInit, databaseFactoryFfi;
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

    if (_db != null) {
      return _db!;
    }

    _db = await _initDB();
    return _db!;
  }

  // Tạo và lưu mật khẩu mã hóa database vào secure storage
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

  // Khởi tạo local database cho mobile và desktop
  Future<Database> _initDB() async {
    final bool isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    if (isDesktop) {
      sqfliteFfiInit();
    }

    final dbPath = isDesktop
        ? await databaseFactoryFfi.getDatabasesPath()
        : await getDatabasesPath();

    final path = join(dbPath, 'chat_local_secure.db');

    // Tạo bảng lưu cache tin nhắn local
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
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: onCreateLogic,
        ),
      );
    }

    final String dbPassword = await _getSecureDbPassword();

    return await openDatabase(
      path,
      version: 1,
      password: dbPassword,
      onCreate: onCreateLogic,
    );
  }

  // Cập nhật nội dung và loại tin nhắn trong cache local
  Future<void> updateMessageContent(
    String messageId,
    String newContent,
    String newType,
  ) async {
    if (kIsWeb) {
      return;
    }

    try {
      final db = await database;

      await db.update(
        'LocalMessages',
        {
          'content': newContent,
          'type': newType,
        },
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint('Lỗi cập nhật local DB: $e');
    }
  }

  // Xóa một tin nhắn khỏi cache local
  Future<void> deleteMessageLocal(String messageId) async {
    if (kIsWeb) {
      return;
    }

    try {
      final db = await database;

      await db.delete(
        'LocalMessages',
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint('Lỗi xóa local DB: $e');
    }
  }

  // Lưu hoặc ghi đè tin nhắn vào cache local
  Future<void> saveMessage(
    Map<String, dynamic> msg,
    String conversationId,
    String? replyText,
  ) async {
    if (kIsWeb) {
      return;
    }

    final db = await database;

    await db.insert(
      'LocalMessages',
      {
        'id': msg['id'] ?? msg['Id'],
        'conversationId': conversationId.toLowerCase(),
        'senderId': msg['senderId'] ?? msg['SenderId'],
        'content': msg['content'] ?? msg['Content'],
        'type': msg['type'] ?? msg['Type'],
        'replyToText': replyText,
        'createdAt': msg['createdAt'] ?? msg['CreatedAt'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Lấy toàn bộ tin nhắn local của một cuộc trò chuyện
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    if (kIsWeb) {
      return [];
    }

    final db = await database;

    return await db.query(
      'LocalMessages',
      where: 'conversationId = ?',
      whereArgs: [conversationId.toLowerCase()],
      orderBy: 'createdAt ASC',
    );
  }

  // Lấy thời gian tin nhắn mới nhất để đồng bộ với server
  Future<String?> getLastMessageTime(String conversationId) async {
    if (kIsWeb) {
      return null;
    }

    final db = await database;

    final result = await db.query(
      'LocalMessages',
      columns: ['createdAt'],
      where: 'conversationId = ?',
      whereArgs: [conversationId.toLowerCase()],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['createdAt'] as String;
    }

    return null;
  }
}