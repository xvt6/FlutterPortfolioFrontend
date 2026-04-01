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

  int _page = 1;
  static const int _pageSize = 10;
  int _totalCount = 0;
  String _query = '';
  String? _vibe;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': _page,
        'pageSize': _pageSize,
      };
      if (_query.isNotEmpty) queryParams['query'] = _query;
      if (_vibe != null && _vibe!.isNotEmpty) queryParams['vibes'] = [_vibe!];

      final response = await _apiService.get('/api/Posts', queryParams: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final totalCountHeader = response.headers['x-total-count'];
        if (!mounted) return;
        setState(() {
          _posts = data.map((item) => Post.fromJson(item)).toList();
          _totalCount = int.tryParse(totalCountHeader ?? '') ?? _posts.length;
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
                    _fetchPosts();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search Posts',
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
                  _fetchPosts();
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
                                      final url = '${ApiService.baseUrl}/api/audio/download?fileIdentifiers=${audio.fileIdentifier}&fileType=mp3';
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
                    _fetchPosts();
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
                    _fetchPosts();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
