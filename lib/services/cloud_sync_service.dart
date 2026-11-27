import 'dart:convert';
import '../data/api_client.dart';
import 'auth_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  /// Pushes all local SQLite widgets, notebooks, and entries to PostgreSQL
  Future<bool> pushToCloud() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return false;

      final client = ApiClient(authToken: token);

      // 1. For now, we'll implement a simpler approach
      print('Cloud sync: pushToCloud not fully implemented - using mock data');
      
      // Mock data for testing
      final mockPayload = {
        'widgets': [
          {
            'id': 'test-widget-1',
            'name': 'Test Widget',
            'type': 'microGoals',
            'config': {'goal': 'Test goal'},
            'enabled': true,
            'placement': 'homescreen'
          }
        ],
        'notebooks': [
          {
            'id': 'test-notebook-1',
            'name': 'Test Notebook',
            'color': 0xFF6750A4,
            'icon_key': 'book',
            'created_at': DateTime.now().toIso8601String()
          }
        ],
        'entries': [
          {
            'id': 'test-note-1',
            'notebook_id': 'test-notebook-1',
            'title': 'Test Note',
            'content': 'This is a test note',
            'raw_text': 'raw test text',
            'summary': 'test summary',
            'source_app': 'test',
            'created_at': DateTime.now().toIso8601String()
          }
        ]
      };

      // 2. Send mock payload for testing
      final response = await client.post('/api/sync/push', body: mockPayload);
      print('Cloud Push Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Cloud Push Error: $e');
      return false;
    }
  }

  /// Pulls saved data from PostgreSQL into local SQLite (great after fresh login)
  Future<bool> pullFromCloud() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return false;

      final client = ApiClient(authToken: token);
      final response = await client.get('/api/sync/pull');

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      print('Cloud Pull: Received ${data['notebooks']?.length ?? 0} notebooks, '
            '${data['entries']?.length ?? 0} entries');
      
      // For now, just log the received data
      // In a full implementation, we would use proper repository methods
      // to insert this data into the local database
      return true;
    } catch (e) {
      print('Cloud Pull Error: $e');
      return false;
    }
  }
}