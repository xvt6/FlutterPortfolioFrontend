import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  Future<void> checkAuthStatus() async {
    _token = await _apiService.getToken();
    _isAuthenticated = _token != null;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);

      if (response.statusCode == 200) {
        _token = await _apiService.getToken();
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
