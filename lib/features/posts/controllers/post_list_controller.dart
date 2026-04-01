import 'package:flutter/foundation.dart';
import '../../../core/models/post.dart';
import '../services/post_service.dart';

class PostListController extends ChangeNotifier {
  final PostService _postService;

  PostListController(this._postService);

  List<Post> _posts = [];
  bool _isLoading = true;
  int _page = 1;
  static const int _pageSize = 10;
  int _totalCount = 0;
  String _query = '';
  String? _vibe;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  int get page => _page;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  String get query => _query;
  String? get vibe => _vibe;

  int get totalPages => (_totalCount / _pageSize).ceil();

  Future<void> fetchPosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _postService.fetchPosts(
        page: _page,
        pageSize: _pageSize,
        query: _query,
        vibe: _vibe,
        requireAuth: false,
      );
      _posts = result['posts'];
      _totalCount = result['totalCount'];
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPage(int page) {
    if (page < 1 || (totalCount > 0 && page > totalPages)) return;
    _page = page;
    fetchPosts();
  }

  void setQuery(String query) {
    _query = query;
    _page = 1;
    fetchPosts();
  }

  void setVibe(String? vibe) {
    _vibe = vibe;
    _page = 1;
    fetchPosts();
  }

  void refresh() {
    _page = 1;
    fetchPosts();
  }
}
