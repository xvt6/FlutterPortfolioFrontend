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

  static const List<String> _allowedMusicKeys = [
    'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'
  ];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchAudios();
  }

  Future<void> _fetchAudios() async {
    try {
      final response = await _apiService.get('/api/Audio');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _audios = data.map((item) => Audio.fromJson(item)).toList();
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
      final response = await _apiService.get('/api/Posts', requireAuth: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _posts = data.map((item) => Post.fromJson(item)).toList();
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
    final vibesController = TextEditingController(text: 'energetic');
    String? selectedMusicKey = 'C';
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
                      TextFormField(
                        controller: vibesController,
                        decoration: const InputDecoration(labelText: 'Vibes (comma-separated)'),
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
                        // Split vibes by comma and trim whitespace
                        final vibesList = vibesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                        // Create fields map. Note: request.fields in MultipartRequest doesn't support multiple values for the same key easily.
                        // We'll send it as a comma separated string if the backend handles it, or just the first one if it doesn't.
                        // Given the previous code sent it as a string, we'll continue that or try to pass it correctly.
                        final fields = {
                          'Description': descriptionController.text,
                          'BPM': bpmController.text,
                          'MusicKey': selectedMusicKey ?? '',
                          'Vibes': vibesList.isNotEmpty ? vibesList.join(',') : '',
                        };

                        final response = await _apiService.uploadWav(
                          '/api/Audio',
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

  Future<void> _deleteAudio(String identifier) async {
    try {
      final response = await _apiService.delete('/api/Audio/$identifier', requireAuth: true);
      if (!mounted) return;
      if (response.statusCode == 204 || response.statusCode == 200) {
        _fetchAudios();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file deleted')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting audio: $e')),
      );
    }
  }

  Future<void> _deletePost(int id) async {
    try {
      final response = await _apiService.delete('/api/Posts/$id', requireAuth: true);
      if (!mounted) return;
      if (response.statusCode == 204 || response.statusCode == 200) {
        _fetchPosts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
  }

  void _showPostDialog([Post? post]) {
    final titleController = TextEditingController(text: post?.title ?? '');
    final contentController = TextEditingController(text: post?.content ?? '');
    final List<String> selectedAudioIdentifiers =
        post?.audioFiles.map((a) => a.fileIdentifier).toList() ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(post == null ? 'Create Post' : 'Edit Post'),
              content: SingleChildScrollView(
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
                    ..._audios.map((audio) {
                      final isSelected = selectedAudioIdentifiers.contains(audio.fileIdentifier);
                      return CheckboxListTile(
                        title: Text(audio.displayName),
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedAudioIdentifiers.add(audio.fileIdentifier);
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

                    try {
                      final response = post == null
                          ? await _apiService.post('/api/Posts', data, requireAuth: true)
                          : await _apiService.put('/api/Posts/${post.id}', data, requireAuth: true);

                      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
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
          _isUploading
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _pickAndUploadWav,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pick and Upload WAV'),
                ),
          const SizedBox(height: 10),
          _isLoadingAudios
              ? const CircularProgressIndicator()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _audios.length,
                  itemBuilder: (context, index) {
                    final audio = _audios[index];
                    return ListTile(
                      title: Text(audio.displayName),
                      subtitle: Text(audio.fileIdentifier),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAudio(audio.fileIdentifier),
                      ),
                    );
                  },
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
          _isLoadingPosts
              ? const CircularProgressIndicator()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return ListTile(
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
                            onPressed: () => _deletePost(post.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
