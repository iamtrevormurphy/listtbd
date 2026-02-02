import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/list_item.dart';
import '../../data/models/shopping_list.dart';
import '../../data/models/store.dart';
import '../../data/repositories/list_repository.dart';

/// List repository provider
final listRepositoryProvider = Provider<ListRepository>((ref) {
  return ListRepository();
});

/// Current shopping list provider
final currentListProvider = FutureProvider<ShoppingList>((ref) async {
  final repo = ref.watch(listRepositoryProvider);
  return repo.getDefaultList();
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
}

final listNotifierProvider =
    StateNotifierProvider<ListNotifier, AsyncValue<void>>((ref) {
  return ListNotifier(ref.watch(listRepositoryProvider), ref);
});
