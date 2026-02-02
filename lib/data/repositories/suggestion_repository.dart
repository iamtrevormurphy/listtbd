import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/purchase_history.dart';
import '../models/repurchase_suggestion.dart';

class SuggestionRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  SuggestionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  /// Get all active suggestions for the user
  Future<List<RepurchaseSuggestion>> getSuggestions() async {
    final now = DateTime.now().toUtc();

    final response = await _client
        .from('repurchase_suggestions')
        .select()
        .eq('user_id', _userId)
        .eq('status', 'pending')
        .or('dismissed_until.is.null,dismissed_until.lt.${now.toIso8601String()}')
        .order('suggested_at', ascending: false);

    return (response as List)
        .map((json) => RepurchaseSuggestion.fromJson(json))
        .toList();
  }

  /// Generate suggestions based on purchase history
  /// This analyzes patterns and creates suggestions for items due for repurchase
  Future<List<RepurchaseSuggestion>> generateSuggestions() async {
    // Get all purchase history grouped by item
    final historyResponse = await _client
        .from('purchase_history')
        .select()
        .eq('user_id', _userId)
        .order('purchased_at', ascending: true);

    final history = (historyResponse as List)
        .map((json) => PurchaseHistory.fromJson(json))
        .toList();

    // Group by normalized item name
    final itemHistory = <String, List<PurchaseHistory>>{};
    for (final purchase in history) {
      itemHistory
          .putIfAbsent(purchase.itemNameNormalized, () => [])
          .add(purchase);
    }

    // Find items that need repurchasing
    final suggestions = <RepurchaseSuggestion>[];
    final now = DateTime.now().toUtc();

    for (final entry in itemHistory.entries) {
      final purchases = entry.value;

      // Need at least 2 purchases to calculate interval
      if (purchases.length < 2) continue;

      // Calculate average interval between purchases
      final intervals = <int>[];
      for (int i = 1; i < purchases.length; i++) {
        final daysBetween = purchases[i]
            .purchasedAt
            .difference(purchases[i - 1].purchasedAt)
            .inDays;
        if (daysBetween > 0) {
          intervals.add(daysBetween);
        }
      }

      if (intervals.isEmpty) continue;

      final avgInterval = intervals.reduce((a, b) => a + b) ~/ intervals.length;
      final lastPurchase = purchases.last;
      final daysSinceLast = now.difference(lastPurchase.purchasedAt).inDays;

      // Suggest if we're within 10% of the average interval or past it
      final threshold = (avgInterval * 0.9).round();
      if (daysSinceLast >= threshold) {
        // Check if suggestion already exists
        final existing = await _client
            .from('repurchase_suggestions')
            .select()
            .eq('user_id', _userId)
            .eq('item_name', lastPurchase.itemName)
            .eq('status', 'pending')
            .maybeSingle();

        if (existing == null) {
          final suggestion = RepurchaseSuggestion(
            id: _uuid.v4(),
            userId: _userId,
            itemName: lastPurchase.itemName,
            category: lastPurchase.category,
            avgIntervalDays: avgInterval,
            lastPurchasedAt: lastPurchase.purchasedAt,
            suggestedAt: now,
          );

          await _client
              .from('repurchase_suggestions')
              .insert(suggestion.toJson());

          suggestions.add(suggestion);
        }
      }
    }

    return suggestions;
  }

  /// Mark a suggestion as added (user added it to their list)
  Future<void> markAsAdded(String suggestionId) async {
    await _client
        .from('repurchase_suggestions')
        .update({'status': 'added'})
        .eq('id', suggestionId);
  }

  /// Dismiss a suggestion (snooze for 7 days)
  Future<void> dismiss(String suggestionId, {int snoozeDays = 7}) async {
    final dismissUntil = DateTime.now().add(Duration(days: snoozeDays));

    await _client.from('repurchase_suggestions').update({
      'status': 'dismissed',
      'dismissed_until': dismissUntil.toIso8601String(),
    }).eq('id', suggestionId);
  }

  /// Delete a suggestion permanently
  Future<void> delete(String suggestionId) async {
    await _client
        .from('repurchase_suggestions')
        .delete()
        .eq('id', suggestionId);
  }

  /// Get purchase statistics for an item
  Future<Map<String, dynamic>?> getItemStats(String itemName) async {
    final normalized = PurchaseHistory.normalize(itemName);

    final response = await _client
        .from('purchase_history')
        .select()
        .eq('user_id', _userId)
        .eq('item_name_normalized', normalized)
        .order('purchased_at', ascending: true);

    final purchases = (response as List)
        .map((json) => PurchaseHistory.fromJson(json))
        .toList();

    if (purchases.length < 2) return null;

    // Calculate stats
    final intervals = <int>[];
    for (int i = 1; i < purchases.length; i++) {
      final daysBetween = purchases[i]
          .purchasedAt
          .difference(purchases[i - 1].purchasedAt)
          .inDays;
      if (daysBetween > 0) {
        intervals.add(daysBetween);
      }
    }

    if (intervals.isEmpty) return null;

    final avgInterval = intervals.reduce((a, b) => a + b) ~/ intervals.length;
    final lastPurchase = purchases.last.purchasedAt;
    final daysSinceLast = DateTime.now().difference(lastPurchase).inDays;

    return {
      'item_name': itemName,
      'purchase_count': purchases.length,
      'avg_interval_days': avgInterval,
      'last_purchased': lastPurchase,
      'days_since_last': daysSinceLast,
      'next_suggested': lastPurchase.add(Duration(days: avgInterval)),
    };
  }
}
