import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  Future<void> init() async {
    // Firebase Analytics initialization will go here when firebase_core is configured.
    // For now, use a no-op implementation that logs in debug mode.
    debugPrint('[Analytics] initialized');
  }

  void logEvent(String name, [Map<String, Object>? params]) {
    debugPrint('[Analytics] $name ${params ?? ''}');
  }

  void logCategoryView(String category) {
    logEvent('view_category', {'category': category});
  }

  void logPlayAll(String category, int count) {
    logEvent('play_all', {'category': category, 'article_count': count});
  }

  void logTrackPlayed(String articleId, String source) {
    logEvent('track_played', {'article_id': articleId, 'source': source});
  }

  void logError(String type, String message) {
    logEvent('error', {'type': type, 'message': message});
  }
}
