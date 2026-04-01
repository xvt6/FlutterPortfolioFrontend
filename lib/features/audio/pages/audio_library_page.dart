import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/audio_library_controller.dart';
import '../controllers/audio_player_controller.dart';

class AudioLibraryPage extends StatefulWidget {
  const AudioLibraryPage({super.key});

  @override
  State<AudioLibraryPage> createState() => _AudioLibraryPageState();
}

class _AudioLibraryPageState extends State<AudioLibraryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioLibraryController>().fetchAudios();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AudioLibraryController>();
    
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
                    labelText: 'Search Audio',
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
            itemCount: controller.audios.length,
            itemBuilder: (context, index) {
              final audio = controller.audios[index];
              return ListTile(
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
              );
            },
          ),
        ),
        _buildPaginationControls(controller),
      ],
    );
  }

  Widget _buildPaginationControls(AudioLibraryController controller) {
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
