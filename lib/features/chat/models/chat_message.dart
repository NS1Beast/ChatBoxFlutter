// Dành riêng để chứa các Model dữ liệu
class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final String type;

  ChatMessage({
    required this.text, 
    required this.isMe, 
    required this.time, 
    this.type = 'text',
  });
}