import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// API client for FastAPI backend
class ApiClient {
  final http.Client _client;
  final String? authToken;
  
  ApiClient({http.Client? client, this.authToken})
      : _client = client ?? http.Client();
  
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(ApiConfig.buildUrl(endpoint));
    final finalUri = queryParameters != null
        ? uri.replace(queryParameters: queryParameters)
        : uri;
    
    final finalHeaders = {
      ...ApiConfig.defaultHeaders,
      ...?headers,
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
    
    return await _client.get(
      finalUri,
      headers: finalHeaders,
    ).timeout(
      const Duration(milliseconds: ApiConfig.connectTimeout + ApiConfig.receiveTimeout),
    );
  }
  
  Future<http.Response> post(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = {
      ...ApiConfig.defaultHeaders,
      ...?headers,
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
    
    return await _client.post(
      Uri.parse(ApiConfig.buildUrl(endpoint)),
      headers: finalHeaders,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(
      const Duration(milliseconds: ApiConfig.connectTimeout + ApiConfig.receiveTimeout),
    );
  }
  
  Future<http.Response> put(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final finalHeaders = {
      ...ApiConfig.defaultHeaders,
      ...?headers,
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
    
    return await _client.put(
      Uri.parse(ApiConfig.buildUrl(endpoint)),
      headers: finalHeaders,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(
      const Duration(milliseconds: ApiConfig.connectTimeout + ApiConfig.receiveTimeout),
    );
  }
  
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final finalHeaders = {
      ...ApiConfig.defaultHeaders,
      ...?headers,
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
    
    return await _client.delete(
      Uri.parse(ApiConfig.buildUrl(endpoint)),
      headers: finalHeaders,
    ).timeout(
      const Duration(milliseconds: ApiConfig.connectTimeout + ApiConfig.receiveTimeout),
    );
  }
  
  /// Checks if the API is reachable
  Future<bool> checkHealth() async {
    try {
      final response = await get(ApiConfig.health);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  void dispose() {
    _client.close();
  }
}