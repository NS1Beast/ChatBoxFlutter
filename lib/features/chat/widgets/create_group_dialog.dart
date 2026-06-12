import 'package:flutter/material.dart';
import '../../../core/services/group_api_service.dart';
import '../../contacts/ContactsController.dart';

class CreateGroupDialog extends StatefulWidget {
  final ContactsController controller; // 🎯 Lấy controller chứa danh bạ và hàm tìm kiếm

  const CreateGroupDialog({super.key, required this.controller});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  // Lưu trữ những người đã được chọn (ID -> Dữ liệu User)
  final Map<String, dynamic> _selectedUsers = {};
  
  Map<String, dynamic>? _searchResult;
  bool _isSearching = false;
  bool _isCreating = false;

  void _handleCreate() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên nhóm!')));
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 thành viên!')));
      return;
    }

    setState(() => _isCreating = true);
    try {
      await GroupApiService().createGroup(_nameController.text.trim(), _selectedUsers.keys.toList());
      if (mounted) {
        Navigator.pop(context, true); // Đóng popup và báo thành công
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo nhóm thành công!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // 🎯 Hàm tìm kiếm người lạ qua Email
  void _searchStranger() async {
    final email = _searchController.text.trim();
    if (email.isEmpty) {
      setState(() => _searchResult = null);
      return;
    }

    setState(() => _isSearching = true);
    // Tái sử dụng hàm tìm kiếm của ContactsController
    final result = await widget.controller.searchUser(email, context: context);
    setState(() {
      _searchResult = result;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 Danh sách hiển thị: Ưu tiên hiển thị kết quả tìm kiếm, nếu không thì hiển thị bạn bè
    List<dynamic> displayList = _searchResult != null ? [_searchResult!] : widget.controller.friendsList;

    return AlertDialog(
      title: const Text('Tạo nhóm chat mới'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên nhóm', prefixIcon: Icon(Icons.group)),
            ),
            const SizedBox(height: 16),
            
            // 🎯 THANH TÌM KIẾM NGƯỜI LẠ
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _searchStranger(),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo Email để thêm người lạ...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear), 
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResult = null); // Reset về danh bạ
                            }
                          ) 
                        : null,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_search, color: Colors.blue),
                  onPressed: _isSearching ? null : _searchStranger,
                )
              ],
            ),
            const SizedBox(height: 16),
            
            // 🎯 HIỂN THỊ CÁC THÀNH VIÊN ĐÃ CHỌN LÀM TAG (CHIP)
            if (_selectedUsers.isNotEmpty) ...[
              const Text('Đã chọn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 4,
                children: _selectedUsers.values.map((u) {
                  return Chip(
                    label: Text(u['fullName'] ?? u['name'] ?? 'User', style: const TextStyle(fontSize: 12)),
                    onDeleted: () => setState(() => _selectedUsers.remove(u['id'] ?? u['userId'])),
                  );
                }).toList(),
              ),
              const Divider(),
            ],

            Text(_searchResult != null ? 'Kết quả tìm kiếm:' : 'Danh bạ:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // 🎯 DANH SÁCH HIỂN THỊ ĐỂ CHỌN
            Container(
              height: 250, 
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
              child: displayList.isEmpty
                ? const Center(child: Text('Không có ai để hiển thị.'))
                : ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final user = displayList[index];
                      final userId = user['id'] ?? user['userId'];
                      final isSelected = _selectedUsers.containsKey(userId);
                      
                      return CheckboxListTile(
                        title: Text(user['fullName'] ?? user['name'] ?? 'Người dùng'),
                        subtitle: Text(user['email'] ?? ''),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) _selectedUsers[userId] = user;
                            else _selectedUsers.remove(userId);
                          });
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _isCreating ? null : _handleCreate,
          child: _isCreating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Tạo Nhóm'),
        ),
      ],
    );
  }
}