import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/list_item.dart';
import '../models/shopping_list.dart';
import '../models/purchase_history.dart';
import '../models/store.dart';

class ListRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  ListRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ============ Shopping Lists ============

  /// Get all lists for current user
  Future<List<ShoppingList>> getLists() async {
    final response = await _client
        .from('lists')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ShoppingList.fromJson(json))
        .toList();
  }

  /// Get default list (first one) or create if none exists
  Future<ShoppingList> getDefaultList() async {
    final lists = await getLists();
    if (lists.isNotEmpty) return lists.first;

    // Create default list
    final newList = {
      'id': _uuid.v4(),
      'user_id': _userId,
      'name': 'Shopping List',
    };

    final response = await _client
        .from('lists')
        .insert(newList)
        .select()
        .single();

    return ShoppingList.fromJson(response);
  }

  /// Stream of list items (real-time)
  Stream<List<ListItem>> watchItems(String listId, {bool archived = false}) {
    return _client
        .from('items')
        .stream(primaryKey: ['id'])
        .eq('list_id', listId)
        .order('created_at', ascending: false)
        .map((data) => data
            .map((json) => ListItem.fromJson(json))
            .where((item) => item.isArchived == archived)
            .toList());
  }

  // ============ List Items ============

  /// Get all items for a list
  Future<List<ListItem>> getItems(String listId, {bool archived = false}) async {
    final response = await _client
        .from('items')
        .select()
        .eq('list_id', listId)
        .eq('is_archived', archived)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ListItem.fromJson(json))
        .toList();
  }

  /// Add a new item
  Future<ListItem> addItem({
    required String listId,
    required String name,
    String? category,
    double? categoryConfidence,
    String? store,
  }) async {
    final now = DateTime.now().toUtc();
    final newItem = {
      'id': _uuid.v4(),
      'list_id': listId,
      'user_id': _userId,
      'name': name.trim(),
      'category': category,
      'category_confidence': categoryConfidence,
      'store': store,
      'quantity': 1,
      'is_archived': false,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final response = await _client
        .from('items')
        .insert(newItem)
        .select()
        .single();

    return ListItem.fromJson(response);
  }

  /// Update an item
  Future<ListItem> updateItem(ListItem item) async {
    final updated = item.copyWith(updatedAt: DateTime.now().toUtc());

    final response = await _client
        .from('items')
        .update(updated.toJson())
        .eq('id', item.id)
        .select()
        .single();

    return ListItem.fromJson(response);
  }

  /// Archive an item (swipe to complete)
  Future<ListItem> archiveItem(String itemId) async {
    final now = DateTime.now().toUtc();

    final response = await _client
        .from('items')
        .update({
          'is_archived': true,
          'archived_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', itemId)
        .select()
        .single();

    final archivedItem = ListItem.fromJson(response);

    // Record in purchase history
    await _recordPurchase(archivedItem);

    return archivedItem;
  }

  /// Unarchive an item
  Future<ListItem> unarchiveItem(String itemId) async {
    final response = await _client
        .from('items')
        .update({
          'is_archived': false,
          'archived_at': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', itemId)
        .select()
        .single();

    return ListItem.fromJson(response);
  }

  /// Delete an item permanently
  Future<void> deleteItem(String itemId) async {
    await _client.from('items').delete().eq('id', itemId);
  }

  /// Update item category
  Future<ListItem> updateCategory(
    String itemId,
    String category, {
    double? confidence,
  }) async {
    final response = await _client
        .from('items')
        .update({
          'category': category,
          'category_confidence': confidence,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', itemId)
        .select()
        .single();

    return ListItem.fromJson(response);
  }

  /// Update item store
  Future<ListItem> updateStore(String itemId, String? store) async {
    final response = await _client
        .from('items')
        .update({
          'store': store,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', itemId)
        .select()
        .single();

    return ListItem.fromJson(response);
  }

  // ============ Stores ============

  /// Get all stores for current user
  Future<List<Store>> getStores() async {
    final response = await _client
        .from('stores')
        .select()
        .eq('user_id', _userId)
        .order('name', ascending: true);

    return (response as List).map((json) => Store.fromJson(json)).toList();
  }

  /// Add a new store
  Future<Store> addStore(String name) async {
    final newStore = {
      'id': _uuid.v4(),
      'user_id': _userId,
      'name': name.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client
        .from('stores')
        .insert(newStore)
        .select()
        .single();

    return Store.fromJson(response);
  }

  /// Delete a store
  Future<void> deleteStore(String storeId) async {
    await _client.from('stores').delete().eq('id', storeId);
  }

  // ============ Purchase History ============

  /// Record a purchase when item is archived
  Future<void> _recordPurchase(ListItem item) async {
    await _client.from('purchase_history').insert({
      'id': _uuid.v4(),
      'user_id': _userId,
      'item_name': item.name,
      'item_name_normalized': PurchaseHistory.normalize(item.name),
      'category': item.category,
      'purchased_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Get purchase history for an item
  Future<List<PurchaseHistory>> getPurchaseHistory(String itemName) async {
    final normalized = PurchaseHistory.normalize(itemName);

    final response = await _client
        .from('purchase_history')
        .select()
        .eq('user_id', _userId)
        .eq('item_name_normalized', normalized)
        .order('purchased_at', ascending: false);

    return (response as List)
        .map((json) => PurchaseHistory.fromJson(json))
        .toList();
  }

  /// Get all archived items
  Future<List<ListItem>> getArchivedItems(String listId) async {
    return getItems(listId, archived: true);
  }
}
