import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../core/models/audio.dart';

class PostDialog extends StatefulWidget {
  final Post? post;
  final List<Audio> initialAudios;
  final Future<List<Audio>> Function(String query) onSearchAudios;
  final Function(Map<String, dynamic>) onSave;

  const PostDialog({
    super.key,
    this.post,
    required this.initialAudios,
    required this.onSearchAudios,
    required this.onSave,
  });

  @override
  State<PostDialog> createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<String> _selectedAudioIdentifiers;
  List<Audio> _dialogAudios = [];
  String _dialogAudioQuery = '';
  bool _isSearchingAudios = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _contentController = TextEditingController(text: widget.post?.content ?? '');
    _selectedAudioIdentifiers = widget.post?.audioFiles.map((a) => a.fileIdentifier).toList() ?? [];
    _dialogAudios = List.from(widget.initialAudios);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _searchAudios() async {
    setState(() => _isSearchingAudios = true);
    try {
      final results = await widget.onSearchAudios(_dialogAudioQuery);
      setState(() {
        _dialogAudios = results;
      });
    } catch (_) {}
    setState(() => _isSearchingAudios = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.post == null ? 'Create Post' : 'Edit Post'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text('Link Audio Files:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) => _dialogAudioQuery = value,
                onSubmitted: (_) => _searchAudios(),
                decoration: InputDecoration(
                  hintText: 'Search audio to link...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchAudios,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_isSearchingAudios)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 10),
              // Show currently selected audios that might not be in the search results
              ...widget.post?.audioFiles.where((a) => !_dialogAudios.any((da) => da.fileIdentifier == a.fileIdentifier)).map((audio) {
                if (!_selectedAudioIdentifiers.contains(audio.fileIdentifier)) return const SizedBox.shrink();
                return CheckboxListTile(
                  title: Text('${audio.displayName} (Selected)'),
                  value: true,
                  onChanged: (value) {
                    setState(() {
                      if (value == false) {
                        _selectedAudioIdentifiers.remove(audio.fileIdentifier);
                      }
                    });
                  },
                );
              }).toList() ?? [],
              // Show search results
              ..._dialogAudios.map((audio) {
                final isSelected = _selectedAudioIdentifiers.contains(audio.fileIdentifier);
                return CheckboxListTile(
                  title: Text(audio.displayName),
                  subtitle: Text(audio.fileIdentifier),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (!_selectedAudioIdentifiers.contains(audio.fileIdentifier)) {
                          _selectedAudioIdentifiers.add(audio.fileIdentifier);
                        }
                      } else {
                        _selectedAudioIdentifiers.remove(audio.fileIdentifier);
                      }
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave({
              'Title': _titleController.text,
              'Content': _contentController.text,
              'AudioFileIdentifiers': _selectedAudioIdentifiers,
              if (widget.post != null) 'Id': widget.post!.id,
            });
            Navigator.pop(context);
          },
          child: Text(widget.post == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}
