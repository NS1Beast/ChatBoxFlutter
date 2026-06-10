import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import 'VoiceRecordingWidgets.dart'; // Đảm bảo đúng tên file của ông

class ChatInputArea extends StatefulWidget {
  final Function(String text) onSendMessage;
  final Function(String url) onSendGif;
  final Function(int durationSec) onSendVoice;

  const ChatInputArea({
    super.key,
    required this.onSendMessage,
    required this.onSendGif,
    required this.onSendVoice,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _msgController = TextEditingController();
  
  bool _isTyping = false;
  bool _showEmojiPicker = false;
  
  bool _isRecording = false;
  int _recordDuration = 0; 
  Timer? _timer;

  // --- BIẾN TRẠNG THÁI CHO GIPHY ---
  final String _giphyApiKey = 'y9VvoFhrBbC8ddNzM6kx6S6ahYg2UsGo'; 
  List<String> _gifUrls = [];
  bool _isLoadingGifs = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchTrendingGifs(); // Load ảnh GIF thịnh hành lúc mới mở
  }

  @override
  void dispose() {
    _msgController.dispose();
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  // ==========================================
  // LOGIC API GIPHY
  // ==========================================
  Future<void> _fetchTrendingGifs() async {
    if (_giphyApiKey == 'YOUR_GIPHY_API_KEY') return; // Bỏ qua nếu chưa có API Key
    setState(() => _isLoadingGifs = true);
    try {
      final response = await http.get(Uri.parse('https://api.giphy.com/v1/gifs/trending?api_key=$_giphyApiKey&limit=20&rating=g'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _gifUrls = (data['data'] as List).map((gif) => gif['images']['fixed_height']['url'].toString()).toList();
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải GIF: $e');
    } finally {
      setState(() => _isLoadingGifs = false);
    }
  }

  void _searchGifs(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        _fetchTrendingGifs();
        return;
      }
      if (_giphyApiKey == 'YOUR_GIPHY_API_KEY') return;
      
      setState(() => _isLoadingGifs = true);
      try {
        final response = await http.get(Uri.parse('https://api.giphy.com/v1/gifs/search?api_key=$_giphyApiKey&q=$query&limit=20&rating=g'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _gifUrls = (data['data'] as List).map((gif) => gif['images']['fixed_height']['url'].toString()).toList();
          });
        }
      } catch (e) {
        debugPrint('Lỗi tìm GIF: $e');
      } finally {
        setState(() => _isLoadingGifs = false);
      }
    });
  }

  // ==========================================
  // LOGIC GHI ÂM & NHẬP LIỆU
  // ==========================================
  void _startRecording() {
    setState(() {
      _showEmojiPicker = false; 
      _isRecording = true;
      _recordDuration = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordDuration++);
    });
  }

  void _stopRecording({required bool send}) {
    _timer?.cancel();
    final duration = _recordDuration;
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
    if (send) widget.onSendVoice(duration);
  }

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  void _onEmojiSelected(Emoji emoji) {
    final text = _msgController.text;
    final selection = _msgController.selection;
    if (selection.baseOffset == -1) {
      _msgController.text = text + emoji.emoji;
    } else {
      final newText = text.replaceRange(selection.start, selection.end, emoji.emoji);
      _msgController.value = _msgController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + emoji.emoji.length),
      );
    }
    setState(() => _isTyping = _msgController.text.isNotEmpty);
  }

  void _handleSendText() {
    if (_msgController.text.trim().isNotEmpty) {
      widget.onSendMessage(_msgController.text.trim());
      _msgController.clear();
      setState(() {
        _isTyping = false;
        _showEmojiPicker = false;
      });
    }
  }

  // ==========================================
  // XÂY DỰNG GIAO DIỆN
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BẢNG EMOJI/GIF
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          child: _showEmojiPicker ? _buildEmojiAndGifPicker(surfaceColor, primaryColor, textColor) : const SizedBox.shrink(),
        ),

        // THANH NHẬP LIỆU
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          color: surfaceColor,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => SlideTransition(position: Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(animation), child: FadeTransition(opacity: animation, child: child)),
            child: _isRecording ? _buildRecordingBar(textColor, primaryColor) : _buildChatInputBar(textColor, primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiAndGifPicker(Color surfaceColor, Color primaryColor, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 350,
      decoration: BoxDecoration(color: surfaceColor, border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: primaryColor, unselectedLabelColor: textColor.withValues(alpha: 0.5), indicatorColor: primaryColor,
              tabs: const [Tab(text: 'Emoji'), Tab(text: 'GIF')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // THƯ VIỆN EMOJI PICKER CHUẨN XỊN
                  EmojiPicker(
                    onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
                    config: Config(
                      height: 256,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: surfaceColor,
                        columns: 8,
                      ),
                      bottomActionBarConfig: const BottomActionBarConfig(enabled: false), // Tắt bar dưới cho gọn
                      categoryViewConfig: CategoryViewConfig(
                        backgroundColor: surfaceColor,
                        indicatorColor: primaryColor,
                        iconColorSelected: primaryColor,
                        iconColor: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  // TAB TÌM KIẾM GIF BẰNG API
                  Column(
                    children: [
                      // Ô tìm kiếm GIF
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          onChanged: _searchGifs,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm ảnh GIF...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _isLoadingGifs
                          ? const Center(child: CircularProgressIndicator())
                          : _giphyApiKey == 'YOUR_GIPHY_API_KEY'
                            ? Center(child: Text('Vui lòng nhập GIPHY API KEY vào code\nđể xem hàng triệu ảnh GIF thực tế!', textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.5))))
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                                itemCount: _gifUrls.length,
                                itemBuilder: (context, index) {
                                  return InkWell(
                                    onTap: () {
                                      widget.onSendGif(_gifUrls[index]);
                                      setState(() => _showEmojiPicker = false);
                                    }, 
                                    borderRadius: BorderRadius.circular(8), 
                                    child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_gifUrls[index], fit: BoxFit.cover))
                                  );
                                },
                              ),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // (Phần khung chat bên dưới giữ nguyên như lúc nãy)
  Widget _buildChatInputBar(Color textColor, Color primaryColor) {
    return Row(
      key: const ValueKey('chat_input'),
      children: [
        IconButton(icon: Icon(Icons.add_circle_outline_rounded, color: textColor.withValues(alpha: 0.5)), onPressed: () {}),
        IconButton(icon: Icon(Icons.image_outlined, color: textColor.withValues(alpha: 0.5)), onPressed: () {}),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _msgController,
            onChanged: (text) => setState(() => _isTyping = text.isNotEmpty),
            onSubmitted: (_) => _handleSendText(),
            decoration: InputDecoration(
              hintText: 'Nhập tin nhắn...', hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
              filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(_showEmojiPicker ? Icons.keyboard_rounded : Icons.sentiment_satisfied_alt_rounded, color: _showEmojiPicker ? primaryColor : textColor.withValues(alpha: 0.5)), 
                onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker)
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: _isTyping
              ? FloatingActionButton(key: const ValueKey('send'), backgroundColor: primaryColor, elevation: 2, mini: true, onPressed: _handleSendText, child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))
              : FloatingActionButton(key: const ValueKey('mic'), onPressed: _startRecording, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, elevation: 0, mini: true, child: Icon(Icons.mic_none_rounded, color: textColor, size: 22)),
        ),
      ],
    );
  }

  Widget _buildRecordingBar(Color textColor, Color primaryColor) {
    return Row(
      key: const ValueKey('recording_bar'),
      children: [
        IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => _stopRecording(send: false), tooltip: 'Hủy ghi âm'),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [const BlinkingDot(), const SizedBox(width: 8), Text(_formatDuration(_recordDuration), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15))]),
        ),
        const SizedBox(width: 16),
        Expanded(child: VoiceWaveform(primaryColor: primaryColor)), 
        const SizedBox(width: 16),
        FloatingActionButton(onPressed: () => _stopRecording(send: true), backgroundColor: primaryColor, elevation: 2, mini: true, child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
      ],
    );
  }
}