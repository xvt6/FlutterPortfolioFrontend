import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:5023');
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

  Future<void> _updateTokenFromResponse(http.Response response) async {
    // Backend returns token in 'X-New-Token' header for sliding session
    final newToken = response.headers['x-new-token'];
    if (newToken != null) {
      await saveToken(newToken);
    }
  }

  Future<http.Response> login(String username, String password) async {
    final response = await post('/api/Auth/login', {
      'username': username,
      'password': password,
    }, requireAuth: false);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final token = body['token'];
      if (token != null) {
        await saveToken(token);
      }
    }
    return response;
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
      await _updateTokenFromResponse(response);
    }
    return response;
  }

  Future<http.Response> post(String endpoint, dynamic body, {bool requireAuth = false}) async {
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

    if (requireAuth || endpoint == '/api/Auth/login') {
      await _updateTokenFromResponse(response);
    }
    return response;
  }

  Future<http.Response> put(String endpoint, dynamic body, {bool requireAuth = true}) async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (requireAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (requireAuth) {
      await _updateTokenFromResponse(response);
    }
    return response;
  }

  Future<http.StreamedResponse> uploadWav(
    String endpoint,
    List<int> fileBytes,
    String fileName, {
    Map<String, String>? fields,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(http.MultipartFile.fromBytes(
      'File', // Backend expects 'File' based on CreateAudioDto
      fileBytes,
      filename: fileName,
    ));

    final response = await request.send();
    // For streamed responses, getting the sliding token from headers is similar
    final newToken = response.headers['x-new-token'];
    if (newToken != null) {
      await saveToken(newToken);
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
      await _updateTokenFromResponse(response);
    }
    return response;
  }
}
