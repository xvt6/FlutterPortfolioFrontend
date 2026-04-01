import 'package:flutter/material.dart';

class AddVibeDialog extends StatefulWidget {
  final Function(List<String>) onAdd;

  const AddVibeDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddVibeDialog> createState() => _AddVibeDialogState();
}

class _AddVibeDialogState extends State<AddVibeDialog> {
  final _vibeController = TextEditingController();

  @override
  void dispose() {
    _vibeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Vibes'),
      content: TextField(
        controller: _vibeController,
        decoration: const InputDecoration(
          labelText: 'Vibe names (comma-separated)',
          hintText: 'e.g. chill, upbeat, dark',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_vibeController.text.isNotEmpty) {
              final vibes = _vibeController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              if (vibes.isNotEmpty) {
                widget.onAdd(vibes);
              }
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
