import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/audio.dart';
import '../models/post.dart';
import 'dart:convert';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ApiService _apiService = ApiService();
  bool _isUploading = false;
  List<Post> _posts = [];
  List<Audio> _audios = [];
  bool _isLoadingPosts = true;
  bool _isLoadingAudios = true;

  final Set<String> _selectedAudioIdentifiers = {};
  final Set<int> _selectedPostIds = {};
  final Set<String> _selectedVibeNames = {};

  static const List<String> _allowedMusicKeys = [
    'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'
  ];

  int _audioPage = 1;
  int _postPage = 1;
  static const int _pageSize = 10;
  int _totalAudios = 0;
  int _totalPosts = 0;
  String _audioQuery = '';
  String _postQuery = '';

  List<String> _availableVibes = [];
  bool _isLoadingVibes = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchAudios();
    _fetchVibes();
  }

  Future<void> _fetchVibes() async {
    try {
      final response = await _apiService.get('/api/audio/vibes');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _availableVibes = List<String>.from(data);
          _isLoadingVibes = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingVibes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching vibes: $e')),
      );
    }
  }

  Future<void> _addVibes(List<String> vibes) async {
    try {
      final response = await _apiService.post('/api/audio/vibes', vibes, requireAuth: true);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _fetchVibes();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding vibes: $e')),
      );
    }
  }

  Future<void> _deleteVibes(List<String> vibes) async {
    if (vibes.isEmpty) return;
    try {
      final response = await _apiService.delete('/api/audio/vibes', queryParams: {
        'names': vibes
      }, requireAuth: true);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _selectedVibeNames.removeAll(vibes);
        });
        _fetchVibes();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting vibes: $e')),
      );
    }
  }

  Future<void> _fetchAudios() async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': _audioPage,
        'pageSize': _pageSize,
      };
      if (_audioQuery.isNotEmpty) queryParams['query'] = _audioQuery;

      final response = await _apiService.get('/api/audio', queryParams: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final totalCountHeader = response.headers['x-total-count'];
        if (!mounted) return;
        setState(() {
          _audios = data.map((item) => Audio.fromJson(item)).toList();
          _totalAudios = int.tryParse(totalCountHeader ?? '') ?? _audios.length;
          _isLoadingAudios = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAudios = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching audios: $e')),
      );
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': _postPage,
        'pageSize': _pageSize,
      };
      if (_postQuery.isNotEmpty) queryParams['query'] = _postQuery;

      final response = await _apiService.get('/api/Posts', queryParams: queryParams, requireAuth: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final totalCountHeader = response.headers['x-total-count'];
        if (!mounted) return;
        setState(() {
          _posts = data.map((item) => Post.fromJson(item)).toList();
          _totalPosts = int.tryParse(totalCountHeader ?? '') ?? _posts.length;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPosts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $e')),
      );
    }
  }

  Future<void> _pickAndUploadWav() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );

    if (result != null && result.files.single.bytes != null) {
      if (!mounted) return;
      _showUploadAudioDialog(result);
    }
  }

  void _showUploadAudioDialog(FilePickerResult result) {
    final descriptionController = TextEditingController(text: 'Uploaded via Admin Dashboard');
    final bpmController = TextEditingController(text: '120.00');
    final vibesController = TextEditingController();
    String? selectedMusicKey = 'C';
    final Set<String> selectedVibes = {};
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Upload Audio Metadata'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('File: ${result.files.single.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      TextFormField(
                        controller: bpmController,
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
                        value: selectedMusicKey,
                        decoration: const InputDecoration(labelText: 'Music Key'),
                        items: _allowedMusicKeys.map((key) {
                          return DropdownMenuItem(value: key, child: Text(key));
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMusicKey = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Existing Vibes:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_availableVibes.isEmpty)
                        const Text('No existing vibes found.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
                      else
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _availableVibes.map((vibe) {
                            final isSelected = selectedVibes.contains(vibe);
                            return FilterChip(
                              label: Text(vibe),
                              selected: isSelected,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedVibes.add(vibe);
                                  } else {
                                    selectedVibes.remove(vibe);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: vibesController,
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);

                      setState(() {
                        _isUploading = true;
                      });

                      try {
                        // Combine selected existing vibes and newly entered vibes
                        final List<String> newVibes = vibesController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                        
                        final vibesList = {...selectedVibes, ...newVibes}.toList();

                        // Create fields map. ApiService will handle the list by creating multiple 'Vibes' fields.
                        final fields = {
                          'Description': descriptionController.text,
                          'BPM': bpmController.text,
                          'MusicKey': selectedMusicKey ?? '',
                          'Vibes': vibesList,
                        };

                        final response = await _apiService.uploadWav(
                          '/api/audio',
                          result.files.single.bytes!,
                          result.files.single.name,
                          fields: fields,
                        );

                        if (!mounted) return;
                        if (response.statusCode == 201 || response.statusCode == 200) {
                          _fetchAudios();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('WAV file uploaded successfully')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upload failed')),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Upload error: $e')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isUploading = false;
                          });
                        }
                      }
                    }
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAudios(List<String> identifiers) async {
    if (identifiers.isEmpty) return;
    try {
      final response = await _apiService.delete('/api/audio', queryParams: {
        'fileIdentifiers': identifiers
      }, requireAuth: true);
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _selectedAudioIdentifiers.removeAll(identifiers);
        });
        _fetchAudios();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${identifiers.length} audio file(s) deleted')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting audio: $e')),
      );
    }
  }

  Future<void> _deletePosts(List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      final response = await _apiService.delete('/api/Posts', queryParams: {
        'ids': ids
      }, requireAuth: true);
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _selectedPostIds.removeAll(ids);
        });
        _fetchPosts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ids.length} post(s) deleted')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting posts: $e')),
      );
    }
  }

  Future<void> _updateAudios(List<Map<String, dynamic>> updates) async {
    if (updates.isEmpty) return;
    try {
      final response = await _apiService.put('/api/audio', updates, requireAuth: true);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _selectedAudioIdentifiers.clear();
        });
        _fetchAudios();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio metadata updated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating audio: $e')),
      );
    }
  }

  void _showAudioEditDialog([List<Audio>? audiosToEdit]) {
    final audios = audiosToEdit ?? _audios.where((a) => _selectedAudioIdentifiers.contains(a.fileIdentifier)).toList();
    if (audios.isEmpty) return;

    final isBulk = audios.length > 1;
    final descriptionController = TextEditingController(text: isBulk ? '' : audios.first.description);
    final bpmController = TextEditingController(text: isBulk ? '' : audios.first.bpm?.toString() ?? '');
    final vibesController = TextEditingController();
    String? selectedMusicKey = isBulk ? null : audios.first.musicKey;
    final Set<String> selectedVibes = isBulk ? {} : audios.first.vibes.toSet();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isBulk ? 'Bulk Edit ${audios.length} Audios' : 'Edit Audio Metadata'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isBulk) Text('File: ${audios.first.displayName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isBulk) const Text('Only fields you fill will be updated for all selected items.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: isBulk ? 'Leave empty to keep original' : null,
                        ),
                      ),
                      TextFormField(
                        controller: bpmController,
                        decoration: InputDecoration(
                          labelText: 'BPM',
                          hintText: isBulk ? 'Leave empty to keep original' : 'e.g. 128.50',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final n = double.tryParse(value);
                          if (n == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedMusicKey,
                        decoration: InputDecoration(
                          labelText: 'Music Key',
                          hintText: isBulk ? 'Select to change all' : null,
                        ),
                        items: [
                          if (isBulk) const DropdownMenuItem(value: null, child: Text('Keep original')),
                          ..._allowedMusicKeys.map((key) {
                            return DropdownMenuItem(value: key, child: Text(key));
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMusicKey = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Existing Vibes:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_availableVibes.isEmpty)
                        const Text('No existing vibes found.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
                      else
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _availableVibes.map((vibe) {
                            final isSelected = selectedVibes.contains(vibe);
                            return FilterChip(
                              label: Text(vibe),
                              selected: isSelected,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedVibes.add(vibe);
                                  } else {
                                    selectedVibes.remove(vibe);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: vibesController,
                        decoration: InputDecoration(
                          labelText: 'Add New Vibes (comma-separated)',
                          hintText: isBulk ? 'Leave empty to keep original' : 'e.g. moody, chill',
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
                    if (formKey.currentState!.validate()) {
                      final List<Map<String, dynamic>> updates = [];
                      for (final audio in audios) {
                        final Map<String, dynamic> update = {
                          'FileIdentifier': audio.fileIdentifier,
                        };
                        
                        if (!isBulk || descriptionController.text.isNotEmpty) {
                          update['Description'] = descriptionController.text;
                        } else {
                           update['Description'] = audio.description;
                        }

                        if (!isBulk || bpmController.text.isNotEmpty) {
                          update['BPM'] = double.tryParse(bpmController.text);
                        } else {
                           update['BPM'] = audio.bpm;
                        }

                        if (!isBulk || selectedMusicKey != null) {
                          update['MusicKey'] = selectedMusicKey;
                        } else {
                           update['MusicKey'] = audio.musicKey;
                        }

                        final List<String> newVibes = vibesController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        if (!isBulk || selectedVibes.isNotEmpty || newVibes.isNotEmpty) {
                           update['Vibes'] = {...selectedVibes, ...newVibes}.toList();
                        } else {
                           update['Vibes'] = audio.vibes;
                        }

                        updates.add(update);
                      }
                      
                      _updateAudios(updates);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPostDialog([Post? post]) {
    final titleController = TextEditingController(text: post?.title ?? '');
    final contentController = TextEditingController(text: post?.content ?? '');
    final List<String> selectedAudioIdentifiers =
        post?.audioFiles.map((a) => a.fileIdentifier).toList() ?? [];

    List<Audio> dialogAudios = List.from(_audios);
    String dialogAudioQuery = '';
    bool isSearchingAudios = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> searchDialogAudios() async {
              setDialogState(() => isSearchingAudios = true);
              try {
                final response = await _apiService.get('/api/audio', queryParams: {
                  'query': dialogAudioQuery,
                  'pageSize': 20, // Slightly more for the dialog
                });
                if (response.statusCode == 200) {
                  final List<dynamic> data = jsonDecode(response.body);
                  setDialogState(() {
                    dialogAudios = data.map((item) => Audio.fromJson(item)).toList();
                  });
                }
              } catch (_) {}
              setDialogState(() => isSearchingAudios = false);
            }

            return AlertDialog(
              title: Text(post == null ? 'Create Post' : 'Edit Post'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      TextField(
                        controller: contentController,
                        decoration: const InputDecoration(labelText: 'Content'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      const Text('Link Audio Files:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (value) => dialogAudioQuery = value,
                        onSubmitted: (_) => searchDialogAudios(),
                        decoration: InputDecoration(
                          hintText: 'Search audio to link...',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: searchDialogAudios,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (isSearchingAudios)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      const SizedBox(height: 10),
                      // Show currently selected audios that might not be in the search results
                      ...post?.audioFiles.where((a) => !dialogAudios.any((da) => da.fileIdentifier == a.fileIdentifier)).map((audio) {
                         if (!selectedAudioIdentifiers.contains(audio.fileIdentifier)) return const SizedBox.shrink();
                         return CheckboxListTile(
                          title: Text('${audio.displayName} (Selected)'),
                          value: true,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == false) {
                                selectedAudioIdentifiers.remove(audio.fileIdentifier);
                              }
                            });
                          },
                        );
                      }).toList() ?? [],
                      // Show search results
                      ...dialogAudios.map((audio) {
                        final isSelected = selectedAudioIdentifiers.contains(audio.fileIdentifier);
                        return CheckboxListTile(
                          title: Text(audio.displayName),
                          subtitle: Text(audio.fileIdentifier),
                          value: isSelected,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                if (!selectedAudioIdentifiers.contains(audio.fileIdentifier)) {
                                  selectedAudioIdentifiers.add(audio.fileIdentifier);
                                }
                              } else {
                                selectedAudioIdentifiers.remove(audio.fileIdentifier);
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
                  onPressed: () async {
                    final data = {
                      'Title': titleController.text,
                      'Content': contentController.text,
                      'AudioFileIdentifiers': selectedAudioIdentifiers,
                    };
                    if (post != null) {
                      data['Id'] = post.id;
                    }

                    try {
                      final response = post == null
                          ? await _apiService.post('/api/Posts', data, requireAuth: true)
                          : await _apiService.put('/api/Posts', data, requireAuth: true);

                      if (response.statusCode >= 200 && response.statusCode < 300) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        _fetchPosts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(post == null ? 'Post created' : 'Post updated')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text(post == null ? 'Create' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manage Audio Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => _audioQuery = value,
                  onSubmitted: (_) {
                    setState(() {
                      _audioPage = 1;
                      _isLoadingAudios = true;
                    });
                    _fetchAudios();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search Audio',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _pickAndUploadWav,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                    ),
            ],
          ),
          const SizedBox(height: 10),
          _isLoadingAudios
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    if (_audios.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selectedAudioIdentifiers.length == _audios.length && _audios.isNotEmpty,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedAudioIdentifiers.addAll(_audios.map((a) => a.fileIdentifier));
                                  } else {
                                    _selectedAudioIdentifiers.clear();
                                  }
                                });
                              },
                            ),
                            const Text('Select All'),
                            const Spacer(),
                            if (_selectedAudioIdentifiers.isNotEmpty) ...[
                              ElevatedButton.icon(
                                onPressed: () => _showAudioEditDialog(),
                                icon: const Icon(Icons.edit),
                                label: Text('Edit (${_selectedAudioIdentifiers.length})'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _deleteAudios(_selectedAudioIdentifiers.toList()),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: Text('Delete (${_selectedAudioIdentifiers.length})'),
                                style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _audios.length,
                      itemBuilder: (context, index) {
                        final audio = _audios[index];
                        return ListTile(
                          leading: Checkbox(
                            value: _selectedAudioIdentifiers.contains(audio.fileIdentifier),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedAudioIdentifiers.add(audio.fileIdentifier);
                                } else {
                                  _selectedAudioIdentifiers.remove(audio.fileIdentifier);
                                }
                              });
                            },
                          ),
                          title: Text(audio.displayName),
                          subtitle: Text(audio.fileIdentifier),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showAudioEditDialog([audio]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteAudios([audio.fileIdentifier]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildPaginationControls(_audioPage, _totalAudios, (newPage) {
                      setState(() {
                        _audioPage = newPage;
                        _isLoadingAudios = true;
                      });
                      _fetchAudios();
                    }),
                  ],
                ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manage Posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showPostDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Post'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (value) => _postQuery = value,
            onSubmitted: (_) {
              setState(() {
                _postPage = 1;
                _isLoadingPosts = true;
              });
              _fetchPosts();
            },
            decoration: const InputDecoration(
              labelText: 'Search Posts',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          _isLoadingPosts
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    if (_posts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selectedPostIds.length == _posts.length && _posts.isNotEmpty,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedPostIds.addAll(_posts.map((p) => p.id));
                                  } else {
                                    _selectedPostIds.clear();
                                  }
                                });
                              },
                            ),
                            const Text('Select All'),
                            const Spacer(),
                            if (_selectedPostIds.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () => _deletePosts(_selectedPostIds.toList()),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: Text('Delete (${_selectedPostIds.length})'),
                                style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return ListTile(
                          leading: Checkbox(
                            value: _selectedPostIds.contains(post.id),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPostIds.add(post.id);
                                } else {
                                  _selectedPostIds.remove(post.id);
                                }
                              });
                            },
                          ),
                          title: Text(post.title),
                          subtitle: Text('${post.audioFiles.length} audio(s) linked'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showPostDialog(post),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePosts([post.id]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildPaginationControls(_postPage, _totalPosts, (newPage) {
                      setState(() {
                        _postPage = newPage;
                        _isLoadingPosts = true;
                      });
                      _fetchPosts();
                    }),
                  ],
                ),
          const SizedBox(height: 30),
          const Text('Manage Vibes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _isLoadingVibes
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    if (_availableVibes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Text('Select vibes to delete:'),
                            const Spacer(),
                            if (_selectedVibeNames.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () => _deleteVibes(_selectedVibeNames.toList()),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: Text('Delete Selected (${_selectedVibeNames.length})'),
                                style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    Wrap(
                      spacing: 8.0,
                      children: _availableVibes.map((vibe) {
                        final isSelected = _selectedVibeNames.contains(vibe);
                        return FilterChip(
                          label: Text(vibe),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedVibeNames.add(vibe);
                              } else {
                                _selectedVibeNames.remove(vibe);
                              }
                            });
                          },
                          onDeleted: () => _deleteVibes([vibe]),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showAddVibeDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Vibes'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  void _showAddVibeDialog() {
    final vibeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Vibes'),
          content: TextField(
            controller: vibeController,
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
                if (vibeController.text.isNotEmpty) {
                  final vibes = vibeController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  if (vibes.isNotEmpty) {
                    _addVibes(vibes);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls(int currentPage, int totalCount, Function(int) onPageChanged) {
    final totalPages = (totalCount / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          Text('Page $currentPage of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}
