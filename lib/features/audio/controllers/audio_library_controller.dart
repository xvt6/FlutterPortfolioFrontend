import 'package:flutter/foundation.dart';
import '../../../core/models/audio.dart';
import '../services/audio_service.dart';

class AudioLibraryController extends ChangeNotifier {
  final AudioService _audioService;

  AudioLibraryController(this._audioService);

  List<Audio> _audios = [];
  bool _isLoading = true;
  int _page = 1;
  static const int _pageSize = 10;
  int _totalCount = 0;
  String _query = '';
  String? _vibe;

  List<Audio> get audios => _audios;
  bool get isLoading => _isLoading;
  int get page => _page;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  String get query => _query;
  String? get vibe => _vibe;

  int get totalPages => (_totalCount / _pageSize).ceil();

  Future<void> fetchAudios() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _audioService.fetchAudios(
        page: _page,
        pageSize: _pageSize,
        query: _query,
        vibe: _vibe,
      );
      _audios = result['audios'];
      _totalCount = result['totalCount'];
    } catch (e) {
      debugPrint('Error fetching audios: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPage(int page) {
    if (page < 1 || (totalCount > 0 && page > totalPages)) return;
    _page = page;
    fetchAudios();
  }

  void setQuery(String query) {
    _query = query;
    _page = 1;
    fetchAudios();
  }

  void setVibe(String? vibe) {
    _vibe = vibe;
    _page = 1;
    fetchAudios();
  }

  void refresh() {
    _page = 1;
    fetchAudios();
  }
}
