import 'package:flutter/foundation.dart';

@immutable
class RepurchaseSuggestion {
  final String id;
  final String userId;
  final String itemName;
  final String? category;
  final int? avgIntervalDays;
  final DateTime? lastPurchasedAt;
  final DateTime suggestedAt;
  final SuggestionStatus status;
  final DateTime? dismissedUntil;

  const RepurchaseSuggestion({
    required this.id,
    required this.userId,
    required this.itemName,
    this.category,
    this.avgIntervalDays,
    this.lastPurchasedAt,
    required this.suggestedAt,
    this.status = SuggestionStatus.pending,
    this.dismissedUntil,
  });

  factory RepurchaseSuggestion.fromJson(Map<String, dynamic> json) {
    return RepurchaseSuggestion(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      itemName: json['item_name'] as String,
      category: json['category'] as String?,
      avgIntervalDays: json['avg_interval_days'] as int?,
      lastPurchasedAt: json['last_purchased_at'] != null
          ? DateTime.parse(json['last_purchased_at'] as String)
          : null,
      suggestedAt: DateTime.parse(json['suggested_at'] as String),
      status: SuggestionStatus.fromString(json['status'] as String? ?? 'pending'),
      dismissedUntil: json['dismissed_until'] != null
          ? DateTime.parse(json['dismissed_until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_name': itemName,
      'category': category,
      'avg_interval_days': avgIntervalDays,
      'last_purchased_at': lastPurchasedAt?.toIso8601String(),
      'suggested_at': suggestedAt.toIso8601String(),
      'status': status.value,
      'dismissed_until': dismissedUntil?.toIso8601String(),
    };
  }

  RepurchaseSuggestion copyWith({
    String? id,
    String? userId,
    String? itemName,
    String? category,
    int? avgIntervalDays,
    DateTime? lastPurchasedAt,
    DateTime? suggestedAt,
    SuggestionStatus? status,
    DateTime? dismissedUntil,
  }) {
    return RepurchaseSuggestion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      avgIntervalDays: avgIntervalDays ?? this.avgIntervalDays,
      lastPurchasedAt: lastPurchasedAt ?? this.lastPurchasedAt,
      suggestedAt: suggestedAt ?? this.suggestedAt,
      status: status ?? this.status,
      dismissedUntil: dismissedUntil ?? this.dismissedUntil,
    );
  }

  /// How many days since last purchase
  int get daysSinceLastPurchase {
    if (lastPurchasedAt == null) return 0;
    return DateTime.now().difference(lastPurchasedAt!).inDays;
  }

  /// Whether this suggestion is overdue (past average interval)
  bool get isOverdue {
    if (avgIntervalDays == null || lastPurchasedAt == null) return false;
    return daysSinceLastPurchase > avgIntervalDays!;
  }
}

enum SuggestionStatus {
  pending('pending'),
  added('added'),
  dismissed('dismissed');

  final String value;
  const SuggestionStatus(this.value);

  static SuggestionStatus fromString(String value) {
    return SuggestionStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => SuggestionStatus.pending,
    );
  }
}
