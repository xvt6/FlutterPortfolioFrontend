import 'package:flutter/material.dart';
import '../../../core/models/post.dart';

class PostListItem extends StatelessWidget {
  final Post post;
  final bool isSelected;
  final Function(bool?) onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PostListItem({
    super.key,
    required this.post,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: onToggleSelect,
      ),
      title: Text(post.title),
      subtitle: Text('ID: ${post.id}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
