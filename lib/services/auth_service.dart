import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/api_client.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_access_token';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> login(String email, String password) async {
    try {
      // Use ApiClient for better error handling and timeout management
      final client = ApiClient();
      final response = await client.post(
        '/api/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final client = ApiClient();
      final response = await client.post(
        '/api/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await saveToken(data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }
}