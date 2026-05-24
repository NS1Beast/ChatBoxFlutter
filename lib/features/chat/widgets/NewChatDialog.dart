import 'package:flutter/material.dart';

class NewChatDialog extends StatefulWidget {
  const NewChatDialog({super.key});

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  final List<String> _selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cuộc trò chuyện mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Thanh tìm kiếm
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm số điện thoại, tên...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Gợi ý', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            // Danh sách chọn
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  String userName = 'Người dùng ${index + 1}';
                  bool isSelected = _selectedUsers.contains(userName);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${index + 10}')),
                    title: Text(userName),
                    trailing: Checkbox(
                      value: isSelected,
                      activeColor: primaryColor,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedUsers.add(userName);
                          } else {
                            _selectedUsers.remove(userName);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Nút Xác nhận
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedUsers.isEmpty ? null : () => Navigator.pop(context),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text('Bắt đầu chat (${_selectedUsers.length})'),
              ),
            )
          ],
        ),
      ),
    );
  }
}