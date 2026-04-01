import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../posts/services/post_service.dart';

class PostController extends ChangeNotifier {
  final PostService _postService;

  List<Post> _posts = [];
  bool _isLoading = true;
  int _totalPosts = 0;
  int _currentPage = 1;
  static const int _pageSize = 10;
  String _query = '';
  final Set<int> _selectedPostIds = {};
  Timer? _searchTimer;

  PostController(this._postService);

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  int get totalPosts => _totalPosts;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get query => _query;
  Set<int> get selectedPostIds => _selectedPostIds;

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchPosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _postService.fetchPosts(
        page: _currentPage,
        pageSize: _pageSize,
        query: _query,
      );
      _posts = data['posts'];
      _totalPosts = data['totalCount'];
    } catch (_) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPage(int page) {
    _currentPage = page;
    fetchPosts();
  }

  void setQuery(String query) {
    _query = query;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 1;
      fetchPosts();
    });
  }

  void toggleSelect(bool? selected, int id) {
    if (selected == true) {
      _selectedPostIds.add(id);
    } else {
      _selectedPostIds.remove(id);
    }
    notifyListeners();
  }

  void toggleSelectAll(bool? selected) {
    if (selected == true) {
      _selectedPostIds.addAll(_posts.map((p) => p.id));
    } else {
      _selectedPostIds.clear();
    }
    notifyListeners();
  }

  Future<void> deletePosts(List<int> ids) async {
    try {
      await _postService.deletePosts(ids);
      _selectedPostIds.removeAll(ids);
      await fetchPosts();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> createPost(Map<String, dynamic> data) async {
    try {
      await _postService.createPost(data);
      await fetchPosts();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updatePost(Map<String, dynamic> data) async {
    try {
      await _postService.updatePost(data);
      await fetchPosts();
    } catch (_) {
      rethrow;
    }
  }
}
