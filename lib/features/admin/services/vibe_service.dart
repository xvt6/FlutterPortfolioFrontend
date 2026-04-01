import 'dart:convert';
import '../../../core/api/api_service.dart';

class VibeService {
  final ApiService _apiService;

  VibeService(this._apiService);

  Future<List<String>> fetchVibes() async {
    final response = await _apiService.get('/api/audio/vibes');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<String>.from(data);
    }
    throw Exception('Failed to fetch vibes');
  }

  Future<void> addVibes(List<String> vibes) async {
    final response = await _apiService.post('/api/audio/vibes', vibes, requireAuth: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to add vibes');
    }
  }

  Future<void> deleteVibes(List<String> vibes) async {
    if (vibes.isEmpty) return;
    final response = await _apiService.delete('/api/audio/vibes', queryParams: {
      'names': vibes
    }, requireAuth: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete vibes');
    }
  }
}
