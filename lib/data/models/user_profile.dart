import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String? displayName;
  final NotificationPreferences notificationPreferences;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.displayName,
    required this.notificationPreferences,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      notificationPreferences: NotificationPreferences.fromJson(
        json['notification_preferences'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'notification_preferences': notificationPreferences.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    NotificationPreferences? notificationPreferences,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@immutable
class NotificationPreferences {
  final bool dailyDigest;
  final bool repurchaseReminders;

  const NotificationPreferences({
    this.dailyDigest = true,
    this.repurchaseReminders = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      dailyDigest: json['daily_digest'] as bool? ?? true,
      repurchaseReminders: json['repurchase_reminders'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_digest': dailyDigest,
      'repurchase_reminders': repurchaseReminders,
    };
  }
}
