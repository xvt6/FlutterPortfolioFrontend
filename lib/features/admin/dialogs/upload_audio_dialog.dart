import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/audio_utils.dart';

class UploadAudioDialog extends StatefulWidget {
  final FilePickerResult result;
  final List<String> availableVibes;
  final Function(Map<String, dynamic>) onUpload;

  const UploadAudioDialog({
    super.key,
    required this.result,
    required this.availableVibes,
    required this.onUpload,
  });

  @override
  State<UploadAudioDialog> createState() => _UploadAudioDialogState();
}

class _UploadAudioDialogState extends State<UploadAudioDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _bpmController;
  String? _selectedMusicKey = 'C';
  final Set<String> _selectedVibes = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: 'Uploaded via Admin Dashboard');
    _bpmController = TextEditingController(text: '120.00');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _bpmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Audio Metadata'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File: ${widget.result.files.single.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _bpmController,
                decoration: const InputDecoration(
                  labelText: 'BPM',
                  hintText: 'e.g. 128.50',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final n = double.tryParse(value);
                  if (n == null) return 'Enter a valid number';
                  if (value.contains('.')) {
                    final decimals = value.split('.')[1];
                    if (decimals.length > 2) return 'Max 2 decimal places';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedMusicKey,
                decoration: const InputDecoration(labelText: 'Music Key'),
                items: allowedMusicKeys.map((key) {
                  return DropdownMenuItem(value: key, child: Text(key));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMusicKey = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Select Existing Vibes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (widget.availableVibes.isEmpty)
                const Text('No existing vibes found.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
              else
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: widget.availableVibes.map((vibe) {
                    final isSelected = _selectedVibes.contains(vibe);
                    return FilterChip(
                      label: Text(vibe),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedVibes.add(vibe);
                          } else {
                            _selectedVibes.remove(vibe);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
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
            if (_formKey.currentState!.validate()) {
              final allVibes = _selectedVibes.toList();

              widget.onUpload({
                'description': _descriptionController.text,
                'bpm': double.tryParse(_bpmController.text) ?? 120.0,
                'musicKey': _selectedMusicKey,
                'vibes': allVibes,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
