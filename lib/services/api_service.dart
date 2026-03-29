import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'https://api.example.com'; // Replace with real base URL
  static const String tokenKey = 'admin_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  void _updateTokenFromResponse(http.Response response) {
    // Assuming backend returns token in 'X-Token' header for sliding session
    final newToken = response.headers['x-token'];
    if (newToken != null) {
      saveToken(newToken);
    }
  }

  Future<http.Response> get(String endpoint, {bool requireAuth = false}) async {
    final Map<String, String> headers = {};
    if (requireAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    if (requireAuth) {
      _updateTokenFromResponse(response);
    }
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool requireAuth = false}) async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (requireAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (requireAuth || endpoint == '/login') {
      _updateTokenFromResponse(response);
    }
    return response;
  }

  Future<http.StreamedResponse> uploadWav(String endpoint, List<int> fileBytes, String fileName) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    final response = await request.send();
    // For streamed responses, getting the sliding token from headers is similar
    final newToken = response.headers['x-token'];
    if (newToken != null) {
      saveToken(newToken);
    }
    return response;
  }

  Future<http.Response> delete(String endpoint, {bool requireAuth = true}) async {
    final Map<String, String> headers = {};
    if (requireAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    if (requireAuth) {
      _updateTokenFromResponse(response);
    }
    return response;
  }
}
