import 'package:flutter/material.dart';

import '../../../core/services/group_api_service.dart';
import '../../contacts/ContactsController.dart';

class AddMemberDialog extends StatefulWidget {
  final ContactsController controller;
  final String conversationId;

  const AddMemberDialog({
    super.key,
    required this.controller,
    required this.conversationId,
  });

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _searchController = TextEditingController();

  final Map<String, dynamic> _selectedUsers = {};

  Map<String, dynamic>? _searchResult;
  bool _isSearching = false;
  bool _isAdding = false;

  // Thêm các người dùng đã chọn vào nhóm
  void _handleAdd() async {
    if (_selectedUsers.isEmpty) {
      return;
    }

    setState(() => _isAdding = true);

    try {
      await GroupApiService().addMembers(
        widget.conversationId,
        _selectedUsers.keys.toList(),
      );

      if (mounted) {
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm thành viên thành công!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  // Tìm người dùng theo email để thêm vào nhóm
  void _searchStranger() async {
    final email = _searchController.text.trim();

    if (email.isEmpty) {
      setState(() => _searchResult = null);
      return;
    }

    setState(() => _isSearching = true);

    final result = await widget.controller.searchUser(
      email,
      context: context,
    );

    setState(() {
      _searchResult = result;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> displayList = _searchResult != null
        ? [_searchResult!]
        : widget.controller.friendsList;

    return AlertDialog(
      title: const Text('Thêm thành viên'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _searchStranger(),
                    decoration: InputDecoration(
                      hintText: 'Tìm Email để thêm người lạ...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResult = null);
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.person_search,
                          color: Colors.blue,
                        ),
                  onPressed: _isSearching ? null : _searchStranger,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedUsers.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedUsers.values.map((user) {
                  return Chip(
                    label: Text(
                      user['fullName'] ?? user['name'] ?? 'User',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedUsers.remove(user['id'] ?? user['userId']);
                      });
                    },
                  );
                }).toList(),
              ),
              const Divider(),
            ],
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: displayList.isEmpty
                  ? const Center(
                      child: Text('Không có ai để hiển thị.'),
                    )
                  : ListView.builder(
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final user = displayList[index];
                        final userId = user['id'] ?? user['userId'];
                        final isSelected = _selectedUsers.containsKey(userId);

                        return CheckboxListTile(
                          title: Text(
                            user['fullName'] ?? user['name'] ?? 'Người dùng',
                          ),
                          subtitle: Text(user['email'] ?? ''),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedUsers[userId] = user;
                              } else {
                                _selectedUsers.remove(userId);
                              }
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isAdding || _selectedUsers.isEmpty ? null : _handleAdd,
          child: _isAdding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Thêm vào nhóm'),
        ),
      ],
    );
  }
}