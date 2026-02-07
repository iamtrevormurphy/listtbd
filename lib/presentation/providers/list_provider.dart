import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/list_item.dart';
import '../../data/models/shopping_list.dart';
import '../../data/models/store.dart';
import '../../data/repositories/list_repository.dart';
import '../../main.dart' show preferencesService;

/// List repository provider
final listRepositoryProvider = Provider<ListRepository>((ref) {
  return ListRepository();
});

/// All shopping lists for the user
final allListsProvider = FutureProvider<List<ShoppingList>>((ref) async {
  final repo = ref.watch(listRepositoryProvider);
  return repo.getLists();
});

/// Currently selected list ID (persisted in state and local storage)
final selectedListIdProvider = StateProvider<String?>((ref) {
  // Initialize from saved preferences
  return preferencesService.lastListId;
});

/// Current shopping list provider - returns null if no list is selected
final currentListProvider = FutureProvider<ShoppingList?>((ref) async {
  final repo = ref.watch(listRepositoryProvider);
  final selectedId = ref.watch(selectedListIdProvider);

  if (selectedId != null) {
    try {
      return await repo.getList(selectedId);
    } catch (_) {
      // If selected list doesn't exist, clear the saved preference
      Future.microtask(() {
        ref.read(selectedListIdProvider.notifier).state = null;
        preferencesService.clearLastListId();
      });
      return null;
    }
  }

  // No list selected - return null to show All Lists page
  return null;
});

/// Active (non-archived) items stream
final activeItemsProvider = StreamProvider.family<List<ListItem>, String>((ref, listId) {
  final repo = ref.watch(listRepositoryProvider);
  return repo.watchItems(listId, archived: false);
});

/// Archived items stream
final archivedItemsProvider = StreamProvider.family<List<ListItem>, String>((ref, listId) {
  final repo = ref.watch(listRepositoryProvider);
  return repo.watchItems(listId, archived: true);
});

/// User's stores
final storesProvider = FutureProvider<List<Store>>((ref) async {
  final repo = ref.watch(listRepositoryProvider);
  return repo.getStores();
});

/// Sort mode enum
enum SortMode { none, store, aisle }

/// Current sort mode
final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.none);

/// Items grouped by store
final itemsByStoreProvider = Provider.family<Map<String, List<ListItem>>, List<ListItem>>((ref, items) {
  final grouped = <String, List<ListItem>>{};

  for (final item in items) {
    final store = item.store ?? 'No Store';
    grouped.putIfAbsent(store, () => []).add(item);
  }

  // Sort stores alphabetically, but keep 'No Store' at the end
  final sortedKeys = grouped.keys.toList()
    ..sort((a, b) {
      if (a == 'No Store') return 1;
      if (b == 'No Store') return -1;
      return a.compareTo(b);
    });

  return {for (var key in sortedKeys) key: grouped[key]!};
});

/// Items grouped by aisle (category)
final itemsByAisleProvider = Provider.family<Map<String, List<ListItem>>, List<ListItem>>((ref, items) {
  final grouped = <String, List<ListItem>>{};

  for (final item in items) {
    final aisle = item.category ?? 'Other';
    grouped.putIfAbsent(aisle, () => []).add(item);
  }

  // Sort aisles alphabetically, but keep 'Other' at the end
  final sortedKeys = grouped.keys.toList()
    ..sort((a, b) {
      if (a == 'Other') return 1;
      if (b == 'Other') return -1;
      return a.compareTo(b);
    });

  return {for (var key in sortedKeys) key: grouped[key]!};
});

// Keep old provider for backwards compatibility
final groupedItemsProvider = itemsByAisleProvider;

/// List actions notifier
class ListNotifier extends StateNotifier<AsyncValue<void>> {
  final ListRepository _repository;
  final Ref _ref;

  ListNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<ListItem?> addItem({
    required String listId,
    required String name,
    String? category,
    String? store,
  }) async {
    if (name.trim().isEmpty) return null;

    state = const AsyncValue.loading();
    ListItem? result;

    state = await AsyncValue.guard(() async {
      result = await _repository.addItem(
        listId: listId,
        name: name,
        category: category,
        store: store,
      );
    });

    return result;
  }

  Future<void> archiveItem(String itemId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.archiveItem(itemId);
    });
  }

  Future<void> unarchiveItem(String itemId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.unarchiveItem(itemId);
    });
  }

  Future<void> deleteItem(String itemId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteItem(itemId);
    });
  }

  Future<void> updateItem(ListItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateItem(item);
    });
  }

  Future<void> updateCategory(
    String itemId,
    String category, {
    double? confidence,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateCategory(itemId, category, confidence: confidence);
    });
  }

  Future<void> updateStore(String itemId, String? store) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateStore(itemId, store);
    });
  }

  Future<void> reorderItems(List<String> itemIds) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.reorderItems(itemIds);
    });
  }

  Future<Store?> addStore(String name) async {
    if (name.trim().isEmpty) return null;

    state = const AsyncValue.loading();
    Store? result;

    state = await AsyncValue.guard(() async {
      result = await _repository.addStore(name);
      _ref.invalidate(storesProvider);
    });

    return result;
  }

  /// Create a new shopping list
  Future<ShoppingList?> createList({
    required String name,
    String? description,
    String? icon,
    String type = 'grocery',
  }) async {
    if (name.trim().isEmpty) return null;

    state = const AsyncValue.loading();
    ShoppingList? result;

    state = await AsyncValue.guard(() async {
      result = await _repository.createList(
        name: name,
        description: description,
        icon: icon,
        type: type,
      );
      _ref.invalidate(allListsProvider);
    });

    return result;
  }

  /// Switch to a different list
  void switchList(String listId) {
    _ref.read(selectedListIdProvider.notifier).state = listId;
    // Save to preferences for persistence across app launches
    preferencesService.setLastListId(listId);
    _ref.invalidate(currentListProvider);
  }

  /// Update a list's name, description, icon, and type
  Future<ShoppingList?> updateList({
    required String listId,
    String? name,
    String? description,
    String? icon,
    String? type,
  }) async {
    state = const AsyncValue.loading();
    ShoppingList? result;

    state = await AsyncValue.guard(() async {
      result = await _repository.updateList(
        listId: listId,
        name: name,
        description: description,
        icon: icon,
        type: type,
      );
      _ref.invalidate(allListsProvider);
      _ref.invalidate(currentListProvider);
    });

    return result;
  }

  /// Delete a list
  Future<void> deleteList(String listId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteList(listId);
      _ref.invalidate(allListsProvider);

      // If we deleted the current list, clear selection and saved preference
      final currentId = _ref.read(selectedListIdProvider);
      if (currentId == listId) {
        _ref.read(selectedListIdProvider.notifier).state = null;
        preferencesService.clearLastListId();
        _ref.invalidate(currentListProvider);
      }
    });
  }
}

final listNotifierProvider =
    StateNotifierProvider<ListNotifier, AsyncValue<void>>((ref) {
  return ListNotifier(ref.watch(listRepositoryProvider), ref);
});
