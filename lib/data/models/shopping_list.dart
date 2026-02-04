import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class ShoppingList {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Available icons for lists
  static const List<ListIconOption> availableIcons = [
    ListIconOption('checklist', Icons.checklist_rounded, 'Checklist'),
    ListIconOption('cart', Icons.shopping_cart_outlined, 'Shopping Cart'),
    ListIconOption('basket', Icons.shopping_basket_outlined, 'Basket'),
    ListIconOption('bag', Icons.shopping_bag_outlined, 'Shopping Bag'),
    ListIconOption('store', Icons.store_outlined, 'Store'),
    ListIconOption('home', Icons.home_outlined, 'Home'),
    ListIconOption('kitchen', Icons.kitchen_outlined, 'Kitchen'),
    ListIconOption('restaurant', Icons.restaurant_outlined, 'Restaurant'),
    ListIconOption('cake', Icons.cake_outlined, 'Party'),
    ListIconOption('flight', Icons.flight_outlined, 'Travel'),
    ListIconOption('camping', Icons.forest_outlined, 'Camping'),
    ListIconOption('pets', Icons.pets_outlined, 'Pets'),
    ListIconOption('child', Icons.child_care_outlined, 'Kids'),
    ListIconOption('fitness', Icons.fitness_center_outlined, 'Fitness'),
    ListIconOption('medical', Icons.medical_services_outlined, 'Health'),
    ListIconOption('gift', Icons.card_giftcard_outlined, 'Gifts'),
  ];

  /// Get the icon data for this list
  IconData get iconData {
    final option = availableIcons.firstWhere(
      (o) => o.id == icon,
      orElse: () => availableIcons.first,
    );
    return option.icon;
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ShoppingList copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents an icon option for a list
class ListIconOption {
  final String id;
  final IconData icon;
  final String label;

  const ListIconOption(this.id, this.icon, this.label);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingList &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
