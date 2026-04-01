import 'package:flutter/material.dart';

class VibeSection extends StatelessWidget {
  final List<String> availableVibes;
  final bool isLoading;
  final Set<String> selectedVibeNames;
  final VoidCallback onAdd;
  final Function(List<String>) onDelete;
  final Function(bool, String) onToggleSelect;
  final Function(String) onDeleteVibe;

  const VibeSection({
    super.key,
    required this.availableVibes,
    required this.isLoading,
    required this.selectedVibeNames,
    required this.onAdd,
    required this.onDelete,
    required this.onToggleSelect,
    required this.onDeleteVibe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manage Vibes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        isLoading
            ? const CircularProgressIndicator()
            : Column(
                children: [
                  if (availableVibes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Text('Select vibes to delete:'),
                          const Spacer(),
                          if (selectedVibeNames.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => onDelete(selectedVibeNames.toList()),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: Text('Delete Selected (${selectedVibeNames.length})'),
                              style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 8.0,
                    children: availableVibes.map((vibe) {
                      final isSelected = selectedVibeNames.contains(vibe);
                      return FilterChip(
                        label: Text(vibe),
                        selected: isSelected,
                        onSelected: (selected) => onToggleSelect(selected, vibe),
                        onDeleted: () => onDeleteVibe(vibe),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vibes'),
                  ),
                ],
              ),
      ],
    );
  }
}
