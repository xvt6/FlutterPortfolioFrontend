import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/audio.dart';
import '../../audio/services/audio_service.dart';

class AudioController extends ChangeNotifier {
  final AudioService _audioService;

  List<Audio> _audios = [];
  bool _isLoading = true;
  int _totalAudios = 0;
  int _currentPage = 1;
  static const int _pageSize = 10;
  String _query = '';
  final Set<String> _selectedAudioIdentifiers = {};
  bool _isUploading = false;
  Timer? _searchTimer;

  AudioController(this._audioService);

  List<Audio> get audios => _audios;
  bool get isLoading => _isLoading;
  int get totalAudios => _totalAudios;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get query => _query;
  Set<String> get selectedAudioIdentifiers => _selectedAudioIdentifiers;
  bool get isUploading => _isUploading;

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAudios() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _audioService.fetchAudios(
        page: _currentPage,
        pageSize: _pageSize,
        query: _query,
      );
      _audios = data['audios'];
      _totalAudios = data['totalCount'];
    } catch (_) {
      // Error handling
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPage(int page) {
    _currentPage = page;
    fetchAudios();
  }

  void setQuery(String query) {
    _query = query;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 1;
      fetchAudios();
    });
  }

  void toggleSelect(bool? selected, String identifier) {
    if (selected == true) {
      _selectedAudioIdentifiers.add(identifier);
    } else {
      _selectedAudioIdentifiers.remove(identifier);
    }
    notifyListeners();
  }

  void toggleSelectAll(bool? selected) {
    if (selected == true) {
      _selectedAudioIdentifiers.addAll(_audios.map((a) => a.fileIdentifier));
    } else {
      _selectedAudioIdentifiers.clear();
    }
    notifyListeners();
  }

  Future<void> deleteAudios(List<String> identifiers) async {
    try {
      await _audioService.deleteAudios(identifiers);
      _selectedAudioIdentifiers.removeAll(identifiers);
      await fetchAudios();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateAudios(List<Map<String, dynamic>> updates) async {
    try {
      await _audioService.updateAudios(updates);
      _selectedAudioIdentifiers.clear();
      await fetchAudios();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> uploadAudio(List<int> bytes, String name, Map<String, dynamic> fields) async {
    _isUploading = true;
    notifyListeners();
    try {
      final response = await _audioService.uploadAudio(bytes, name, fields);
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchAudios();
      } else {
        throw Exception('Upload failed');
      }
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}
