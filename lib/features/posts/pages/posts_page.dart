import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../controllers/post_list_controller.dart';
import '../../audio/controllers/audio_player_controller.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostListController>().fetchPosts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostListController>();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) {
                    controller.setQuery(value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Search Posts',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            controller.setQuery('');
                          },
                        )
                      : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.refresh(),
              ),
            ],
          ),
        ),
        if (controller.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
            itemCount: controller.posts.length,
            itemBuilder: (context, index) {
              final post = controller.posts[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(post.content),
                  trailing: Text(post.createdAt.toIso8601String().split('T')[0]),
                  children: [
                    if (post.audioFiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Linked Audio:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...post.audioFiles.map((audio) => ListTile(
                                  leading: const Icon(Icons.audiotrack),
                                  title: Text(audio.displayName),
                                  subtitle: Text(audio.description),
                                  trailing: Consumer<AudioPlayerController>(
                                    builder: (context, audioPlayerController, child) {
                                      final isPlaying = audioPlayerController.isInitialized && 
                                                      audioPlayerController.currentAudio?.fileIdentifier == audio.fileIdentifier && 
                                                      audioPlayerController.player.playing;
                                      return IconButton(
                                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                                        onPressed: () async {
                                          if (!audioPlayerController.isInitialized) return;
                                          try {
                                            await audioPlayerController.playAudio(audio);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error playing audio: $e')),
                                              );
                                            }
                                          }
                                        },
                                      );
                                    },
                                  ),
                                )),
                          ],
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No audio files linked to this post.'),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildPaginationControls(controller),
      ],
    );
  }

  Widget _buildPaginationControls(PostListController controller) {
    if (controller.totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.page > 1
                ? () => controller.setPage(controller.page - 1)
                : null,
          ),
          Text('Page ${controller.page} of ${controller.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.page < controller.totalPages
                ? () => controller.setPage(controller.page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
