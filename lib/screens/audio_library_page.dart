import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio.dart';
import '../services/api_service.dart';
import '../providers/audio_provider.dart';

class AudioLibraryPage extends StatefulWidget {
  const AudioLibraryPage({super.key});

  @override
  State<AudioLibraryPage> createState() => _AudioLibraryPageState();
}

class _AudioLibraryPageState extends State<AudioLibraryPage> {
  final ApiService _apiService = ApiService();
  List<Audio> _audios = [];
  bool _isLoading = true;

  int _page = 1;
  static const int _pageSize = 10;
  int _totalCount = 0;
  String _query = '';
  String? _vibe;

  @override
  void initState() {
    super.initState();
    _fetchAudios();
  }

  Future<void> _fetchAudios() async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': _page,
        'pageSize': _pageSize,
      };
      if (_query.isNotEmpty) queryParams['query'] = _query;
      if (_vibe != null && _vibe!.isNotEmpty) queryParams['vibes'] = [_vibe!];

      final response = await _apiService.get('/api/audio', queryParams: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final totalCountHeader = response.headers['x-total-count'];
        if (!mounted) return;
        setState(() {
          _audios = data.map((item) => Audio.fromJson(item)).toList();
          _totalCount = int.tryParse(totalCountHeader ?? '') ?? _audios.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching audios: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    _query = value;
                  },
                  onSubmitted: (_) {
                    setState(() {
                      _page = 1;
                      _isLoading = true;
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
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _page = 1;
                    _isLoading = true;
                  });
                  _fetchAudios();
                },
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
            itemCount: _audios.length,
            itemBuilder: (context, index) {
              final audio = _audios[index];
              return ListTile(
                leading: const Icon(Icons.audiotrack),
                title: Text(audio.displayName),
                subtitle: Text(audio.description),
                trailing: Consumer<AudioProvider>(
                  builder: (context, audioProvider, child) {
                    final isPlaying = audioProvider.isInitialized && audioProvider.currentAudio?.fileIdentifier == audio.fileIdentifier && audioProvider.player.playing;
                    return IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: () async {
                        if (!audioProvider.isInitialized) return;
                        try {
                          await audioProvider.playAudio(audio);
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
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_totalCount / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () {
                    setState(() {
                      _page--;
                      _isLoading = true;
                    });
                    _fetchAudios();
                  }
                : null,
          ),
          Text('Page $_page of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages
                ? () {
                    setState(() {
                      _page++;
                      _isLoading = true;
                    });
                    _fetchAudios();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
