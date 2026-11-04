import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/installed_widget.dart';
import '../models/marketplace_listing.dart';
import '../models/widget_type.dart';
import 'api_client.dart';
import 'seed_catalog.dart';

/// API-backed marketplace repository for V2
class ApiMarketplaceRepository {
  final ApiClient _client;
  
  ApiMarketplaceRepository({required String? authToken})
      : _client = ApiClient(authToken: authToken);
  
  /// Get all marketplace listings from the API
  Future<List<MarketplaceListing>> all({
    int skip = 0,
    int limit = 100,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      
      if (category != null) {
        queryParams['category'] = category;
      }
      
      final response = await _client.get(
        '/listings/',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => _parseListingFromApi(item)).whereType<MarketplaceListing>().toList();
      } else {
        throw Exception('Failed to load listings: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to local seed data if API is unavailable
      print('API error, using local seed data: $e');
      return _getLocalSeedListings();
    }
  }
  
  /// Increment download count for a listing
  Future<void> incrementDownloads(String id) async {
    try {
      // Note: The current API doesn't have a dedicated endpoint for this
      // In a real implementation, we'd either:
      // 1. Have a dedicated endpoint like POST /listings/{id}/download
      // 2. Include it in the update endpoint
      // For now, we'll just make a PUT request to update the listing
      final response = await _client.get('/listings/$id');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentDownloads = data['download_count'] as int;
        
        final updateData = {
          'download_count': currentDownloads + 1,
        };
        
        await _client.put(
          '/listings/$id',
          body: updateData,
        );
      }
    } catch (e) {
      print('Failed to increment downloads: $e');
      // Silently fail - downloads are not critical
    }
  }
  
  /// Publish a user's widget as a new listing
  Future<MarketplaceListing> publish(
    InstalledWidget widget, {
    required String description,
    required List<String> tags,
  }) async {
    try {
      final listingData = {
        'name': widget.name,
        'description': description,
        'category': _getCategoryFromWidgetType(widget.type),
        'author': 'You', // Would be replaced with actual user name from auth
        'config_schema': widget.type.sanitizeConfig(
          widget.config,
          defaultConfigs[widget.type]!,
        ),
        'tags': tags,
        'price': 0.0,
      };
      
      final response = await _client.post(
        '/listings/',
        body: listingData,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseListingFromApi(data);
      } else {
        throw Exception('Failed to publish listing: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to publish listing: $e');
      rethrow;
    }
  }
  
  /// Users may only remove their own listings
  Future<void> unpublish(String id) async {
    try {
      final response = await _client.delete('/listings/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to unpublish listing: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to unpublish listing: $e');
      rethrow;
    }
  }
  
  /// Add a listing to user's favorites
  Future<void> addFavorite(int userId, int listingId) async {
    try {
      final response = await _client.post(
        '/users/$userId/favorites/$listingId',
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add favorite: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to add favorite: $e');
      rethrow;
    }
  }
  
  /// Remove a listing from user's favorites
  Future<void> removeFavorite(int userId, int listingId) async {
    try {
      final response = await _client.delete(
        '/users/$userId/favorites/$listingId',
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove favorite: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to remove favorite: $e');
      rethrow;
    }
  }
  
  /// Get user's favorite listings
  Future<List<MarketplaceListing>> getFavorites(int userId) async {
    try {
      final response = await _client.get('/users/$userId/favorites/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => _parseListingFromApi(item)).whereType<MarketplaceListing>().toList();
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to load favorites: $e');
      return [];
    }
  }
  
  // Helper methods
  
  MarketplaceListing _parseListingFromApi(Map<String, dynamic> data) {
    return MarketplaceListing.fromApiData(data)!;
  }
  
  WidgetType _getWidgetTypeFromCategory(String category) {
    // Map API categories to our widget types
    switch (category.toLowerCase()) {
      case 'productivity':
        return WidgetType.microGoals;
      case 'entertainment':
        return WidgetType.cricketTimer;
      case 'health':
        return WidgetType.reminder;
      case 'notes':
        return WidgetType.textNotebook;
      default:
        return WidgetType.microGoals; // Default fallback
    }
  }
  
  String _getCategoryFromWidgetType(WidgetType type) {
    // Map our widget types to API categories
    switch (type) {
      case WidgetType.microGoals:
        return 'productivity';
      case WidgetType.cricketTimer:
        return 'entertainment';
      case WidgetType.reminder:
        return 'health';
      case WidgetType.textNotebook:
        return 'notes';
    }
  }
  
  List<MarketplaceListing> _getLocalSeedListings() {
    // Fallback to local seed data when API is unavailable
    // This is a simplified version - in production, you'd want proper seed data
    return [
      MarketplaceListing(
        id: 'api-fallback-1',
        type: WidgetType.microGoals,
        name: 'Daily Tasks',
        description: 'Track your daily goals and progress',
        author: 'System',
        source: ListingSource.developer,
        config: defaultConfigs[WidgetType.microGoals]!,
        tags: ['productivity', 'goals'],
        downloads: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      MarketplaceListing(
        id: 'api-fallback-2',
        type: WidgetType.cricketTimer,
        name: 'Cricket Score Tracker',
        description: 'Track cricket scores and wickets',
        author: 'System',
        source: ListingSource.developer,
        config: defaultConfigs[WidgetType.cricketTimer]!,
        tags: ['sports', 'entertainment'],
        downloads: 75,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
    ];
  }
  
  void dispose() {
    _client.dispose();
  }
}