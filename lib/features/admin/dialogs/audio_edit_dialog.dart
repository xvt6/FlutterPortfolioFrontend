import 'package:flutter/material.dart';
import '../../../core/models/audio.dart';
import '../utils/audio_utils.dart';

class AudioEditDialog extends StatefulWidget {
  final List<Audio> targetAudios;
  final List<String> availableVibes;
  final Function(Map<String, dynamic>) onUpdate;

  const AudioEditDialog({
    super.key,
    required this.targetAudios,
    required this.availableVibes,
    required this.onUpdate,
  });

  @override
  State<AudioEditDialog> createState() => _AudioEditDialogState();
}

class _AudioEditDialogState extends State<AudioEditDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _bpmController;
  late TextEditingController _vibesController;
  String? _selectedMusicKey;
  final Set<String> _selectedVibes = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final isSingle = widget.targetAudios.length == 1;
    _descriptionController = TextEditingController(text: isSingle ? widget.targetAudios.first.description : '');
    _bpmController = TextEditingController(text: isSingle ? (widget.targetAudios.first.bpm?.toStringAsFixed(2) ?? '') : '');
    _vibesController = TextEditingController();
    _selectedMusicKey = isSingle ? widget.targetAudios.first.musicKey : null;
    if (isSingle) {
      _selectedVibes.addAll(widget.targetAudios.first.vibes);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _bpmController.dispose();
    _vibesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = widget.targetAudios.length == 1;
    return AlertDialog(
      title: Text(isSingle ? 'Edit Audio: ${widget.targetAudios.first.displayName}' : 'Edit ${widget.targetAudios.length} Audios'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: isSingle ? '' : 'Leave blank to keep original',
                ),
              ),
              TextFormField(
                controller: _bpmController,
                decoration: InputDecoration(
                  labelText: 'BPM',
                  hintText: isSingle ? 'e.g. 128.50' : 'Leave blank to keep original',
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
                decoration: InputDecoration(
                  labelText: 'Music Key',
                  hintText: isSingle ? '' : 'Select to update all',
                ),
                items: [
                  if (!isSingle) const DropdownMenuItem(value: null, child: Text('Keep Original')),
                  ...allowedMusicKeys.map((key) {
                    return DropdownMenuItem(value: key, child: Text(key));
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMusicKey = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Update Vibes:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              TextFormField(
                controller: _vibesController,
                decoration: const InputDecoration(
                  labelText: 'Add New Vibes (comma-separated)',
                  hintText: 'e.g. moody, chill',
                ),
              ),
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
              final newVibes = _vibesController.text
                  .split(',')
                  .map((v) => v.trim())
                  .where((v) => v.isNotEmpty)
                  .toList();
              
              final allVibes = {..._selectedVibes, ...newVibes}.toList();

              widget.onUpdate({
                'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
                'bpm': _bpmController.text.isNotEmpty ? double.tryParse(_bpmController.text) : null,
                'musicKey': _selectedMusicKey,
                'vibes': allVibes.isNotEmpty ? allVibes : (isSingle ? [] : null),
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
