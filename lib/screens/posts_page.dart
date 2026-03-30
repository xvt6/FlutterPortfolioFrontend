import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final ApiService _apiService = ApiService();
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await _apiService.get('/api/Posts');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _posts = data.map((item) => Post.fromJson(item)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
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
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () {
                                final url = '${ApiService.baseUrl}/api/Audio/${audio.fileIdentifier}/mp3';
                                // Logic to play audio
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
    );
  }
}
