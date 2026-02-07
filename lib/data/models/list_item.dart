import 'package:flutter/foundation.dart';

@immutable
class ListItem {
  final String id;
  final String listId;
  final String userId;
  final String name;
  final String? category; // Store aisle (e.g., "Refrigerated", "International")
  final double? categoryConfidence;
  final String? store; // Store name (e.g., "Whole Foods", "Costco")
  final String? notes;
  final int quantity;
  final int sortOrder; // For manual ordering in project lists
  final bool isArchived;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ListItem({
    required this.id,
    required this.listId,
    required this.userId,
    required this.name,
    this.category,
    this.categoryConfidence,
    this.store,
    this.notes,
    this.quantity = 1,
    this.sortOrder = 0,
    this.isArchived = false,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      categoryConfidence: json['category_confidence'] != null
          ? (json['category_confidence'] as num).toDouble()
          : null,
      store: json['store'] as String?,
      notes: json['notes'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'user_id': userId,
      'name': name,
      'category': category,
      'category_confidence': categoryConfidence,
      'store': store,
      'notes': notes,
      'quantity': quantity,
      'sort_order': sortOrder,
      'is_archived': isArchived,
      'archived_at': archivedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy with the given fields replaced
  ListItem copyWith({
    String? id,
    String? listId,
    String? userId,
    String? name,
    String? category,
    double? categoryConfidence,
    String? store,
    String? notes,
    int? quantity,
    int? sortOrder,
    bool? isArchived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ListItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      store: store ?? this.store,
      notes: notes ?? this.notes,
      quantity: quantity ?? this.quantity,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
