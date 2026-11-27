class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Changed from localhost to 10.0.2.2
  );
  
  static const int connectTimeout = 5000;
  static const int receiveTimeout = 10000;
  
  static const String listings = '/listings/';
  static const String users = '/users/';
  static const String favorites = '/favorites/';
  static const String health = '/health';
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}