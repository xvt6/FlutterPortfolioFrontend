import 'package:flutter/material.dart';
import '../../../core/models/audio.dart';

class AudioListItem extends StatelessWidget {
  final Audio audio;
  final bool isSelected;
  final Function(bool?) onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AudioListItem({
    super.key,
    required this.audio,
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
      title: Text(audio.displayName),
      subtitle: Text(audio.fileIdentifier),
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
