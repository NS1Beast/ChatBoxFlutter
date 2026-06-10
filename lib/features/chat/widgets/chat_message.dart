class ChatMessage {
  final String? id;
  final String text;
  final String type;
  final bool isMe;
  final String time;
  
  // 🎯 THÊM 2 BIẾN NÀY CHO TÍNH NĂNG MỚI
  final String? replyToText; 
  Map<String, int> reactions; // Dùng Map để lưu Emoji và Số lượng (VD: {'❤️': 2, '👍': 1})

  ChatMessage({
    this.id,
    required this.text,
    required this.type,
    required this.isMe,
    required this.time,
    this.replyToText,
    Map<String, int>? reactions, // Khởi tạo Map cảm xúc
  }) : reactions = reactions ?? {}; // Nếu rỗng thì gán mặc định là {}
}