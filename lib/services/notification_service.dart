import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

import '../data/models/repurchase_suggestion.dart';
import '../data/repositories/suggestion_repository.dart';

/// JavaScript interop for notification functions
@JS('listappNotifications.isSupported')
external bool _jsIsSupported();

@JS('listappNotifications.getPermission')
external String _jsGetPermission();

@JS('listappNotifications.requestPermission')
external JSPromise<JSString> _jsRequestPermission();

@JS('listappNotifications.send')
external bool _jsSendNotification(String title, String body, String? icon);

/// Service for handling notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  Timer? _checkTimer;
  SuggestionRepository? _suggestionRepo;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      _startPeriodicCheck();
    }
  }

  /// Check if notifications are supported
  bool get isSupported {
    if (!kIsWeb) return false;
    try {
      return _jsIsSupported();
    } catch (e) {
      return false;
    }
  }

  /// Get current permission status
  String get permission {
    if (!kIsWeb) return 'unsupported';
    try {
      return _jsGetPermission();
    } catch (e) {
      return 'unsupported';
    }
  }

  /// Request notification permission
  Future<String> requestPermission() async {
    if (!kIsWeb) return 'unsupported';
    try {
      final result = await _jsRequestPermission().toDart;
      return result.toDart;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return 'denied';
    }
  }

  /// Send a notification
  bool sendNotification(String title, String body, {String? icon}) {
    if (!kIsWeb) return false;
    try {
      return _jsSendNotification(title, body, icon);
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }

  /// Start periodic check for suggestions (every hour)
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => checkAndNotify(),
    );

    // Also check after a short delay on start
    Future.delayed(const Duration(seconds: 30), checkAndNotify);
  }

  /// Check for due suggestions and send notifications
  Future<void> checkAndNotify() async {
    if (!isSupported || permission != 'granted') return;

    try {
      _suggestionRepo ??= SuggestionRepository();

      // Generate new suggestions based on purchase history
      await _suggestionRepo!.generateSuggestions();

      // Get active suggestions
      final suggestions = await _suggestionRepo!.getSuggestions();

      // Filter to overdue items only
      final overdue = suggestions.where((s) => s.isOverdue).toList();

      if (overdue.isNotEmpty) {
        _showSuggestionNotification(overdue);
      }
    } catch (e) {
      debugPrint('Error checking suggestions: $e');
    }
  }

  /// Show a notification for overdue items
  void _showSuggestionNotification(List<RepurchaseSuggestion> suggestions) {
    final count = suggestions.length;
    final title = count == 1
        ? 'Time to restock ${suggestions.first.itemName}!'
        : 'Time to restock $count items';

    final body = count == 1
        ? 'You usually buy this every ${suggestions.first.avgIntervalDays} days'
        : suggestions.take(3).map((s) => s.itemName).join(', ');

    sendNotification(title, body);
  }

  /// Dispose the service
  void dispose() {
    _checkTimer?.cancel();
  }
}
