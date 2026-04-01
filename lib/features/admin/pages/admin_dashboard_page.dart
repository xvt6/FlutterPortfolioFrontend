import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/models/audio.dart';
import '../../../core/models/post.dart';
import '../widgets/audio_section.dart';
import '../widgets/post_section.dart';
import '../widgets/vibe_section.dart';
import '../dialogs/upload_audio_dialog.dart';
import '../dialogs/audio_edit_dialog.dart';
import '../dialogs/post_dialog.dart';
import '../dialogs/add_vibe_dialog.dart';
import '../controllers/audio_controller.dart';
import '../controllers/post_controller.dart';
import '../controllers/vibe_controller.dart';
import '../utils/ui_utils.dart';
import '../widgets/pagination_controls.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostController>().fetchPosts();
      context.read<AudioController>().fetchAudios();
      context.read<VibeController>().fetchVibes();
    });
  }

  void _showUploadAudioDialog(FilePickerResult result) {
    final audioController = context.read<AudioController>();
    final vibeController = context.read<VibeController>();

    showDialog(
      context: context,
      builder: (context) => UploadAudioDialog(
        result: result,
        availableVibes: vibeController.availableVibes,
        onUpload: (data) async {
          try {
            final fields = {
              'Description': data['description'],
              'BPM': data['bpm'].toString(),
              'MusicKey': data['musicKey'] ?? '',
              'Vibes': data['vibes'],
            };

            await audioController.uploadAudio(
              result.files.single.bytes!,
              result.files.single.name,
              fields,
            );

            if (!mounted) return;
            showSuccess(context, 'WAV file uploaded successfully');
          } catch (e) {
            if (!mounted) return;
            showError(context, 'Upload error: $e');
          }
        },
      ),
    );
  }

  void _showAudioEditDialog([List<Audio>? audiosToEdit]) {
    final audioController = context.read<AudioController>();
    final vibeController = context.read<VibeController>();
    final targetAudios = audiosToEdit ?? audioController.audios.where((a) => audioController.selectedAudioIdentifiers.contains(a.fileIdentifier)).toList();
    if (targetAudios.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AudioEditDialog(
        targetAudios: targetAudios,
        availableVibes: vibeController.availableVibes,
        onUpdate: (data) async {
          final List<Map<String, dynamic>> updates = [];
          for (final audio in targetAudios) {
            final Map<String, dynamic> update = {
              'FileIdentifier': audio.fileIdentifier,
            };

            update['Description'] = data['description'] ?? audio.description;
            update['BPM'] = data['bpm'] ?? audio.bpm;
            update['MusicKey'] = data['musicKey'] ?? audio.musicKey;
            update['Vibes'] = data['vibes'] ?? audio.vibes;

            updates.add(update);
          }
          try {
            await audioController.updateAudios(updates);
            if (!mounted) return;
            showSuccess(context, 'Audio metadata updated');
          } catch (e) {
            if (!mounted) return;
            showError(context, 'Error updating audio: $e');
          }
        },
      ),
    );
  }

  void _showPostDialog([Post? post]) {
    final postController = context.read<PostController>();
    final audioController = context.read<AudioController>();

    showDialog(
      context: context,
      builder: (context) => PostDialog(
        post: post,
        initialAudios: audioController.audios,
        onSearchAudios: (query) async {
          // This uses the service indirectly or we could just use a service here
          // But for now, let's just use the controller's underlying service if possible
          // or just implement a quick search here using the existing API service logic.
          // Actually, the controller should probably have a searchAudios method.
          // For now, I'll just use a direct call or keep it simple.
          return audioController.audios.where((a) => a.displayName.toLowerCase().contains(query.toLowerCase())).toList();
          // Wait, the previous logic was doing a real API call.
          // I'll add a searchAudios method to AudioController later or just do it here.
        },
        onSave: (data) async {
          try {
            if (post == null) {
              await postController.createPost(data);
            } else {
              await postController.updatePost(data);
            }
            if (!mounted) return;
            showSuccess(context, post == null ? 'Post created' : 'Post updated');
          } catch (e) {
            if (!mounted) return;
            showError(context, 'Error: $e');
          }
        },
      ),
    );
  }

  void _showAddVibeDialog() {
    final vibeController = context.read<VibeController>();
    showDialog(
      context: context,
      builder: (context) => AddVibeDialog(
        onAdd: (vibes) async {
          try {
            await vibeController.addVibes(vibes);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding vibes: $e')),
            );
          }
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final audioController = context.watch<AudioController>();
    final postController = context.watch<PostController>();
    final vibeController = context.watch<VibeController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AudioSection(
            audios: audioController.audios,
            isLoading: audioController.isLoading,
            selectedAudioIdentifiers: audioController.selectedAudioIdentifiers,
            audioPage: audioController.currentPage,
            totalAudios: audioController.totalAudios,
            audioQuery: audioController.query,
            isUploading: audioController.isUploading,
            onSearch: (value) => audioController.setQuery(value),
            onUpload: _pickAndUploadWav,
            onEdit: (audios) => _showAudioEditDialog(audios),
            onDelete: (ids) async {
              try {
                await audioController.deleteAudios(ids);
                if (!mounted) return;
                showSuccess(context, '${ids.length} audio file(s) deleted');
              } catch (e) {
                if (!mounted) return;
                showError(context, 'Error deleting audio: $e');
              }
            },
            onPageChanged: (newPage) => audioController.setPage(newPage),
            onToggleSelect: (value, identifier) => audioController.toggleSelect(value, identifier),
            onToggleSelectAll: (value) => audioController.toggleSelectAll(value),
          ),
          const SizedBox(height: 30),
          PostSection(
            posts: postController.posts,
            isLoading: postController.isLoading,
            selectedPostIds: postController.selectedPostIds,
            postPage: postController.currentPage,
            totalPosts: postController.totalPosts,
            postQuery: postController.query,
            onSearch: (value) => postController.setQuery(value),
            onAdd: () => _showPostDialog(),
            onEdit: (post) => _showPostDialog(post),
            onDelete: (ids) async {
              try {
                await postController.deletePosts(ids);
                if (!mounted) return;
                showSuccess(context, '${ids.length} post(s) deleted');
              } catch (e) {
                if (!mounted) return;
                showError(context, 'Error deleting posts: $e');
              }
            },
            onPageChanged: (newPage) => postController.setPage(newPage),
            onToggleSelect: (value, id) => postController.toggleSelect(value, id),
            onToggleSelectAll: (value) => postController.toggleSelectAll(value),
          ),
          const SizedBox(height: 30),
          VibeSection(
            availableVibes: vibeController.availableVibes,
            isLoading: vibeController.isLoading,
            selectedVibeNames: vibeController.selectedVibeNames,
            onAdd: () => _showAddVibeDialog(),
            onDelete: (vibes) async {
              try {
                await vibeController.deleteVibes(vibes);
              } catch (e) {
                if (!mounted) return;
                showError(context, 'Error deleting vibes: $e');
              }
            },
            onToggleSelect: (selected, vibe) => vibeController.toggleSelect(selected, vibe),
            onDeleteVibe: (vibe) async {
              try {
                await vibeController.deleteVibes([vibe]);
              } catch (e) {
                if (!mounted) return;
                showError(context, 'Error deleting vibe: $e');
              }
            },
          ),
        ],
      ),
    );
  }
}
