import 'package:flutter/foundation.dart';

@immutable
class PurchaseHistory {
  final String id;
  final String userId;
  final String itemName;
  final String itemNameNormalized;
  final String? category;
  final DateTime purchasedAt;

  const PurchaseHistory({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.itemNameNormalized,
    this.category,
    required this.purchasedAt,
  });

  factory PurchaseHistory.fromJson(Map<String, dynamic> json) {
    return PurchaseHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      itemName: json['item_name'] as String,
      itemNameNormalized: json['item_name_normalized'] as String,
      category: json['category'] as String?,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_name': itemName,
      'item_name_normalized': itemNameNormalized,
      'category': category,
      'purchased_at': purchasedAt.toIso8601String(),
    };
  }

  /// Normalize item name for consistent matching
  static String normalize(String name) {
    return name.toLowerCase().trim();
  }
}
