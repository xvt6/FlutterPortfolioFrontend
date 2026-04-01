import 'dart:convert';
import '../../../core/models/post.dart';
import '../../../core/api/api_service.dart';

class PostService {
  final ApiService _apiService;

  PostService(this._apiService);

  Future<Map<String, dynamic>> fetchPosts({
    int page = 1,
    int pageSize = 10,
    String query = '',
    String? vibe,
    bool requireAuth = false,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'pageSize': pageSize,
    };
    if (query.isNotEmpty) queryParams['query'] = query;
    if (vibe != null && vibe.isNotEmpty) queryParams['vibes'] = [vibe];

    final response = await _apiService.get('/api/Posts', queryParams: queryParams, requireAuth: requireAuth);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final totalCountHeader = response.headers['x-total-count'];
      final posts = data.map((item) => Post.fromJson(item)).toList();
      final totalCount = int.tryParse(totalCountHeader ?? '') ?? posts.length;
      return {'posts': posts, 'totalCount': totalCount};
    }
    throw Exception('Failed to fetch posts');
  }

  Future<void> createPost(Map<String, dynamic> data) async {
    final response = await _apiService.post('/api/Posts', data, requireAuth: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create post');
    }
  }

  Future<void> updatePost(Map<String, dynamic> data) async {
    final response = await _apiService.put('/api/Posts', data, requireAuth: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update post');
    }
  }

  Future<void> deletePosts(List<int> ids) async {
    if (ids.isEmpty) return;
    final response = await _apiService.delete('/api/Posts', queryParams: {
      'ids': ids
    }, requireAuth: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete posts');
    }
  }
}
