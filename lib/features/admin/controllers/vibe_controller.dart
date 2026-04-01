import 'package:flutter/material.dart';
import '../services/vibe_service.dart';

class VibeController extends ChangeNotifier {
  final VibeService _vibeService;

  List<String> _availableVibes = [];
  bool _isLoading = true;
  final Set<String> _selectedVibeNames = {};

  VibeController(this._vibeService);

  List<String> get availableVibes => _availableVibes;
  bool get isLoading => _isLoading;
  Set<String> get selectedVibeNames => _selectedVibeNames;

  Future<void> fetchVibes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _availableVibes = await _vibeService.fetchVibes();
    } catch (_) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSelect(bool selected, String vibe) {
    if (selected) {
      _selectedVibeNames.add(vibe);
    } else {
      _selectedVibeNames.remove(vibe);
    }
    notifyListeners();
  }

  Future<void> addVibes(List<String> vibes) async {
    try {
      await _vibeService.addVibes(vibes);
      await fetchVibes();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteVibes(List<String> vibes) async {
    try {
      await _vibeService.deleteVibes(vibes);
      _selectedVibeNames.removeAll(vibes);
      await fetchVibes();
    } catch (_) {
      rethrow;
    }
  }
}
