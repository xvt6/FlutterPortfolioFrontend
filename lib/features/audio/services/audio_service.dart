import 'dart:convert';
import '../../../core/models/audio.dart';
import '../../../core/api/api_service.dart';
import 'package:http/http.dart' as http;

class AudioService {
  final ApiService _apiService;

  AudioService(this._apiService);

  Future<Map<String, dynamic>> fetchAudios({
    int page = 1,
    int pageSize = 10,
    String query = '',
    String? vibe,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'pageSize': pageSize,
    };
    if (query.isNotEmpty) queryParams['query'] = query;
    if (vibe != null && vibe.isNotEmpty) queryParams['vibes'] = [vibe];

    final response = await _apiService.get('/api/audio', queryParams: queryParams);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final totalCountHeader = response.headers['x-total-count'];
      final audios = data.map((item) => Audio.fromJson(item)).toList();
      final totalCount = int.tryParse(totalCountHeader ?? '') ?? audios.length;
      return {'audios': audios, 'totalCount': totalCount};
    }
    throw Exception('Failed to fetch audios');
  }

  Future<void> deleteAudios(List<String> identifiers) async {
    if (identifiers.isEmpty) return;
    final response = await _apiService.delete('/api/audio', queryParams: {
      'fileIdentifiers': identifiers
    }, requireAuth: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete audios');
    }
  }

  Future<void> updateAudios(List<Map<String, dynamic>> updates) async {
    if (updates.isEmpty) return;
    final response = await _apiService.put('/api/audio', updates, requireAuth: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update audios');
    }
  }

  Future<http.StreamedResponse> uploadAudio(List<int> fileBytes, String fileName, Map<String, dynamic> fields) async {
    return await _apiService.uploadWav(
      '/api/audio',
      fileBytes,
      fileName,
      fields: fields,
    );
  }
}
