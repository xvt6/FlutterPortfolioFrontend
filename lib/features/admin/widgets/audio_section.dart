import 'package:flutter/material.dart';
import '../../../core/models/audio.dart';
import 'audio_list_item.dart';
import 'pagination_controls.dart';

class AudioSection extends StatelessWidget {
  final List<Audio> audios;
  final bool isLoading;
  final Set<String> selectedAudioIdentifiers;
  final int audioPage;
  final int totalAudios;
  final String audioQuery;
  final bool isUploading;
  final Function(String) onSearch;
  final VoidCallback onUpload;
  final Function(List<Audio>?) onEdit;
  final Function(List<String>) onDelete;
  final Function(int) onPageChanged;
  final Function(bool?, String) onToggleSelect;
  final Function(bool?) onToggleSelectAll;

  const AudioSection({
    super.key,
    required this.audios,
    required this.isLoading,
    required this.selectedAudioIdentifiers,
    required this.audioPage,
    required this.totalAudios,
    required this.audioQuery,
    required this.isUploading,
    required this.onSearch,
    required this.onUpload,
    required this.onEdit,
    required this.onDelete,
    required this.onPageChanged,
    required this.onToggleSelect,
    required this.onToggleSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manage Audio Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: onSearch,
                onSubmitted: (_) => onPageChanged(1),
                decoration: const InputDecoration(
                  labelText: 'Search Audio',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload'),
                  ),
          ],
        ),
        const SizedBox(height: 10),
        isLoading
            ? const CircularProgressIndicator()
            : Column(
                children: [
                  if (audios.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selectedAudioIdentifiers.length == audios.length && audios.isNotEmpty,
                            onChanged: onToggleSelectAll,
                          ),
                          const Text('Select All'),
                          const Spacer(),
                          if (selectedAudioIdentifiers.isNotEmpty) ...[
                            ElevatedButton.icon(
                              onPressed: () => onEdit(null),
                              icon: const Icon(Icons.edit),
                              label: Text('Edit (${selectedAudioIdentifiers.length})'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => onDelete(selectedAudioIdentifiers.toList()),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: Text('Delete (${selectedAudioIdentifiers.length})'),
                              style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: audios.length,
                    itemBuilder: (context, index) {
                      final audio = audios[index];
                      return AudioListItem(
                        audio: audio,
                        isSelected: selectedAudioIdentifiers.contains(audio.fileIdentifier),
                        onToggleSelect: (value) => onToggleSelect(value, audio.fileIdentifier),
                        onEdit: () => onEdit([audio]),
                        onDelete: () => onDelete([audio.fileIdentifier]),
                      );
                    },
                  ),
                  PaginationControls(
                    currentPage: audioPage,
                    totalCount: totalAudios,
                    onPageChanged: onPageChanged,
                  ),
                ],
              ),
      ],
    );
  }
}
