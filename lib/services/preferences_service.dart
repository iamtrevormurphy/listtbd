import 'package:hive_flutter/hive_flutter.dart';

/// Service for storing app preferences locally
class PreferencesService {
  static const String _boxName = 'preferences';
  static const String _lastListIdKey = 'last_list_id';

  Box? _box;

  /// Initialize the preferences box
  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Get the last selected list ID
  String? get lastListId => _box?.get(_lastListIdKey) as String?;

  /// Set the last selected list ID
  Future<void> setLastListId(String? listId) async {
    if (listId != null) {
      await _box?.put(_lastListIdKey, listId);
    } else {
      await _box?.delete(_lastListIdKey);
    }
  }

  /// Check if a last list ID exists
  bool get hasLastList => lastListId != null;

  /// Clear the last list ID
  Future<void> clearLastListId() async {
    await _box?.delete(_lastListIdKey);
  }
}
