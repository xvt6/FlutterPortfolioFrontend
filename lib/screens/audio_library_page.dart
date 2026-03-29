import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/audio.dart';
import '../services/api_service.dart';

class AudioLibraryPage extends StatefulWidget {
  const AudioLibraryPage({super.key});

  @override
  State<AudioLibraryPage> createState() => _AudioLibraryPageState();
}

class _AudioLibraryPageState extends State<AudioLibraryPage> {
  final ApiService _apiService = ApiService();
  List<Audio> _audios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAudios();
  }

  Future<void> _fetchAudios() async {
    try {
      final response = await _apiService.get('/audios');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _audios = data.map((item) => Audio.fromJson(item)).toList();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: _audios.length,
      itemBuilder: (context, index) {
        final audio = _audios[index];
        return ListTile(
          leading: const Icon(Icons.audiotrack),
          title: Text(audio.fileName),
          subtitle: Text('Uploaded: ${audio.uploadedAt.toIso8601String().split('T')[0]}'),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              // Logic to play audio from audio.url
            },
          ),
        );
      },
    );
  }
}
