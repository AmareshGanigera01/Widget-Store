/// Configuration for the FastAPI backend
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const int connectTimeout = 5000; // 5 seconds
  static const int receiveTimeout = 10000; // 10 seconds
  
  // API endpoints
  static const String listings = '/listings/';
  static const String users = '/users/';
  static const String favorites = '/favorites/';
  static const String health = '/health';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Helper method to build full URL
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}