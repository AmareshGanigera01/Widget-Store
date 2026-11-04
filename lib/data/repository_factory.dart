import 'package:flutter/foundation.dart';

import '../models/installed_widget.dart';
import '../models/marketplace_listing.dart';
import 'app_database.dart';
import 'api_marketplace_repository.dart';
import 'repositories.dart';

/// Factory to create repositories based on configuration
class RepositoryFactory {
  final bool useApiBackend;
  final String? apiAuthToken;
  
  RepositoryFactory({
    required this.useApiBackend,
    this.apiAuthToken,
  });
  
  /// Creates the appropriate marketplace repository
  MarketplaceRepository createMarketplaceRepository(AppDatabase db) {
    if (useApiBackend) {
      return _ApiMarketplaceRepositoryWrapper(
        apiRepository: ApiMarketplaceRepository(authToken: apiAuthToken),
        localRepository: MarketplaceRepository(db),
        db: db,
      );
    } else {
      return MarketplaceRepository(db);
    }
  }
  
  /// Creates widget repository (stays local for now)
  WidgetRepository createWidgetRepository(AppDatabase db) {
    return WidgetRepository(db);
  }
  
  /// Creates notebook repository (stays local for now)
  NotebookRepository createNotebookRepository(AppDatabase db) {
    return NotebookRepository(db);
  }
  
  /// Creates progress repository (stays local for now)
  ProgressRepository createProgressRepository(AppDatabase db) {
    return ProgressRepository(db);
  }
}

/// Wrapper that uses API repository but falls back to local repository
class _ApiMarketplaceRepositoryWrapper implements MarketplaceRepository {
  final ApiMarketplaceRepository _apiRepository;
  final MarketplaceRepository _localRepository;
  final AppDatabase _db;
  
  _ApiMarketplaceRepositoryWrapper({
    required ApiMarketplaceRepository apiRepository,
    required MarketplaceRepository localRepository,
    required AppDatabase db,
  }) : _apiRepository = apiRepository,
       _localRepository = localRepository,
       _db = db;
  
  @override
  Future<List<MarketplaceListing>> all() async {
    try {
      return await _apiRepository.all();
    } catch (e) {
      // Fall back to local repository if API fails
      debugPrint('API repository failed, using local fallback: $e');
      return await _localRepository.all();
    }
  }
  
  @override
  Future<void> incrementDownloads(String id) async {
    try {
      await _apiRepository.incrementDownloads(id);
    } catch (e) {
      // Also update local count if API call fails
      debugPrint('Failed to increment downloads via API: $e');
      await _localRepository.incrementDownloads(id);
    }
  }
  
  @override
  Future<MarketplaceListing> publish(
    InstalledWidget widget, {
    required String description,
    required List<String> tags,
  }) async {
    try {
      return await _apiRepository.publish(
        widget,
        description: description,
        tags: tags,
      );
    } catch (e) {
      // Fall back to local publishing
      debugPrint('Failed to publish via API, using local: $e');
      return await _localRepository.publish(
        widget,
        description: description,
        tags: tags,
      );
    }
  }
  
  @override
  Future<void> unpublish(String id) async {
    try {
      await _apiRepository.unpublish(id);
    } catch (e) {
      // Also try to unpublish locally
      debugPrint('Failed to unpublish via API: $e');
      await _localRepository.unpublish(id);
    }
  }
}