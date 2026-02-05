import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme_config.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/list_item.dart';
import '../../../data/models/repurchase_suggestion.dart';
import '../../../data/models/shopping_list.dart' show ShoppingList, ListType;
import '../../../data/models/store.dart';
import '../../../services/ai_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/quick_add_bar.dart';
import '../lists/all_lists_screen.dart';
import '../lists/edit_list_screen.dart';
import '../../widgets/suggestion_card.dart';
import '../../widgets/swipeable_item.dart';
import '../archive/archive_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final currentListAsync = ref.watch(currentListProvider);

    return currentListAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (list) {
        // If no list is selected, navigate to All Lists
        if (list == null) {
          // Navigate to AllListsScreen after the build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AllListsScreen()),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _HomeContent(list: list);
      },
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final ShoppingList list;

  const _HomeContent({required this.list});

  String get listId => list.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(activeItemsProvider(listId));
    final suggestionsAsync = ref.watch(suggestionsProvider);
    final storesAsync = ref.watch(storesProvider);
    final sortMode = ref.watch(sortModeProvider);
    final listNotifier = ref.read(listNotifierProvider.notifier);

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Provisions',
            style: ThemeConfig.youngSerifStyle(
              fontSize: 22,
              color: ThemeConfig.textPrimary,
            ),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          surfaceTintColor: Colors.transparent,
        actions: [
          // Sort toggle - only show for non-project lists
          if (list.type != ListType.project)
            PopupMenuButton<SortMode>(
              icon: Icon(
                sortMode == SortMode.none
                    ? Icons.sort
                    : sortMode == SortMode.store
                        ? Icons.store
                        : Icons.category,
                color: sortMode != SortMode.none
                    ? ThemeConfig.primaryColor
                    : null,
              ),
              tooltip: 'Sort items',
              onSelected: (mode) {
                ref.read(sortModeProvider.notifier).state = mode;
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: SortMode.none,
                  child: Row(
                    children: [
                      Icon(
                        Icons.list,
                        color: sortMode == SortMode.none
                            ? ThemeConfig.primaryColor
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Text('All Items'),
                      if (sortMode == SortMode.none) ...[
                        const Spacer(),
                        Icon(Icons.check, color: ThemeConfig.primaryColor),
                      ],
                    ],
                  ),
                ),
                if (list.supportsStores)
                  PopupMenuItem(
                    value: SortMode.store,
                    child: Row(
                      children: [
                        Icon(
                          Icons.store,
                          color: sortMode == SortMode.store
                              ? ThemeConfig.primaryColor
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text('By Store'),
                        if (sortMode == SortMode.store) ...[
                          const Spacer(),
                          Icon(Icons.check, color: ThemeConfig.primaryColor),
                        ],
                      ],
                    ),
                  ),
                if (list.supportsCategories)
                  PopupMenuItem(
                    value: SortMode.aisle,
                    child: Row(
                      children: [
                        Icon(
                          Icons.category,
                          color: sortMode == SortMode.aisle
                              ? ThemeConfig.primaryColor
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(list.type == ListType.grocery ? 'By Aisle' : 'By Category'),
                        if (sortMode == SortMode.aisle) ...[
                          const Spacer(),
                          Icon(Icons.check, color: ThemeConfig.primaryColor),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Archive',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArchiveScreen(listId: listId),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'signout') {
                await ref.read(authNotifierProvider.notifier).signOut();
              } else if (value == 'stores') {
                _showStoreManagement(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stores',
                child: Row(
                  children: [
                    Icon(Icons.store),
                    SizedBox(width: 8),
                    Text('Manage Stores'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Current list header
          _ListHeader(
            list: list,
            onTap: () => Navigator.push(
              context,
              SlideFromLeftRoute(page: const AllListsScreen()),
            ),
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditListScreen(list: list)),
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (items) {
                final suggestions = suggestionsAsync.valueOrNull ?? [];
                final stores = storesAsync.valueOrNull ?? [];

                if (items.isEmpty && suggestions.isEmpty) {
                  return const _EmptyState();
                }

                return _ContentList(
                  suggestions: suggestions,
                  items: items,
                  stores: stores,
                  sortMode: sortMode,
                  listType: list.type,
                  onAddSuggestion: (s) => _addSuggestion(context, ref, s),
                  onDismissSuggestion: (s) => _dismissSuggestion(ref, s),
                  onArchive: (item) => _archiveItem(context, ref, item),
                  onDelete: (item) => _deleteItem(context, ref, item),
                  onTap: (item) => _editItem(context, ref, item, stores, list.type),
                  onCategoryChanged: (item, category) async {
                    await listNotifier.updateCategory(item.id, category);
                  },
                  onStoreChanged: (item, store) async {
                    await listNotifier.updateStore(item.id, store);
                  },
                );
              },
            ),
          ),
          QuickAddBar(
            onSubmit: (name) => _addItem(ref, name),
            isLoading: ref.watch(listNotifierProvider).isLoading,
          ),
        ],
      ),
      ),
    );
  }

  void _showStoreManagement(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _StoreManagementSheet(),
    );
  }

  Future<void> _addItem(WidgetRef ref, String name) async {
    final notifier = ref.read(listNotifierProvider.notifier);

    // Add item first (appears immediately with no category)
    final item = await notifier.addItem(listId: listId, name: name);

    if (item != null && list.supportsCategories) {
      // Then categorize in background using AI (only for non-project lists)
      final aiService = AIService();
      final result = await aiService.categorizeItem(name, listType: list.type);

      // Update the item with the AI-assigned category
      final category = result['category'] as String?;
      final confidence = result['confidence'] as double?;

      if (category != null) {
        await notifier.updateCategory(item.id, category, confidence: confidence);
      }
    }
  }

  void _archiveItem(BuildContext context, WidgetRef ref, ListItem item) {
    ref.read(listNotifierProvider.notifier).archiveItem(item.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} completed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(listNotifierProvider.notifier).unarchiveItem(item.id);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, ListItem item) async {
    // Await the delete to ensure it completes before showing snackbar
    await ref.read(listNotifierProvider.notifier).deleteItem(item.id);

    // Invalidate the items provider to force refresh
    ref.invalidate(activeItemsProvider(listId));

    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _editItem(BuildContext context, WidgetRef ref, ListItem item, List<Store> stores, ListType listType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditItemSheet(item: item, stores: stores, listType: listType),
    );
  }

  Future<void> _addSuggestion(
    BuildContext context,
    WidgetRef ref,
    RepurchaseSuggestion suggestion,
  ) async {
    // Add the suggested item to the list
    final notifier = ref.read(listNotifierProvider.notifier);
    await notifier.addItem(
      listId: listId,
      name: suggestion.itemName,
      category: suggestion.category,
    );

    // Mark suggestion as added
    await ref.read(suggestionNotifierProvider.notifier).addToList(suggestion);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${suggestion.itemName} added to list')),
      );
    }
  }

  Future<void> _dismissSuggestion(
    WidgetRef ref,
    RepurchaseSuggestion suggestion,
  ) async {
    await ref.read(suggestionNotifierProvider.notifier).dismiss(suggestion);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: ThemeConfig.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your list is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items using the bar below',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ListHeader({
    required this.list,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Arrow on left pointing left
              Icon(
                Icons.chevron_left,
                color: ThemeConfig.textSecondary,
              ),
              const SizedBox(width: 12),
              // List icon - between arrow and name, closer to name
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  list.iconData,
                  color: ThemeConfig.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // List name and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (list.description != null && list.description!.isNotEmpty)
                      Text(
                        list.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ThemeConfig.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Edit button - right aligned
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: ThemeConfig.textSecondary,
                  size: 20,
                ),
                onPressed: onEdit,
                tooltip: 'Edit list',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom page route that slides from left to right (reverse of default)
class SlideFromLeftRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideFromLeftRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

class _ContentList extends ConsumerWidget {
  final List<RepurchaseSuggestion> suggestions;
  final List<ListItem> items;
  final List<Store> stores;
  final SortMode sortMode;
  final ListType listType;
  final Function(RepurchaseSuggestion) onAddSuggestion;
  final Function(RepurchaseSuggestion) onDismissSuggestion;
  final Function(ListItem) onArchive;
  final Function(ListItem) onDelete;
  final Function(ListItem) onTap;
  final Function(ListItem, String) onCategoryChanged;
  final Function(ListItem, String?) onStoreChanged;

  const _ContentList({
    required this.suggestions,
    required this.items,
    required this.stores,
    required this.sortMode,
    required this.listType,
    required this.onAddSuggestion,
    required this.onDismissSuggestion,
    required this.onArchive,
    required this.onDelete,
    required this.onTap,
    required this.onCategoryChanged,
    required this.onStoreChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get grouped items based on sort mode
    final Map<String, List<ListItem>> grouped;
    if (sortMode == SortMode.store) {
      grouped = ref.watch(itemsByStoreProvider(items));
    } else if (sortMode == SortMode.aisle) {
      grouped = ref.watch(itemsByAisleProvider(items));
    } else {
      // No grouping - show all items in a flat list
      grouped = {'': items};
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Suggestions section
        if (suggestions.isNotEmpty)
          SuggestionsList(
            suggestions: suggestions,
            onAdd: onAddSuggestion,
            onDismiss: onDismissSuggestion,
          ),

        // Items (grouped or flat)
        ...grouped.entries.map((entry) {
          final groupName = entry.key;
          final groupItems = entry.value;

          if (sortMode == SortMode.none) {
            // Flat list, no headers
            return Column(
              children: groupItems.map((item) => SwipeableItem(
                item: item,
                listType: listType,
                onArchive: () => onArchive(item),
                onDelete: () => onDelete(item),
                onTap: () => onTap(item),
                onCategoryChanged: (cat) => onCategoryChanged(item, cat),
                onStoreChanged: (store) => onStoreChanged(item, store),
                stores: stores,
              )).toList(),
            );
          }

          // Grouped view with headers
          final emoji = sortMode == SortMode.aisle
              ? (listType == ListType.grocery
                  ? Categories.getEmoji(groupName)
                  : ShoppingCategories.getEmoji(groupName))
              : '🏪';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      groupName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ThemeConfig.primaryColor,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${groupItems.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ThemeConfig.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...groupItems.map((item) => SwipeableItem(
                    item: item,
                    listType: listType,
                    onArchive: () => onArchive(item),
                    onDelete: () => onDelete(item),
                    onTap: () => onTap(item),
                    onCategoryChanged: (cat) => onCategoryChanged(item, cat),
                    onStoreChanged: (store) => onStoreChanged(item, store),
                    stores: stores,
                  )),
            ],
          );
        }),
      ],
    );
  }
}

class _StoreManagementSheet extends ConsumerStatefulWidget {
  const _StoreManagementSheet();

  @override
  ConsumerState<_StoreManagementSheet> createState() => _StoreManagementSheetState();
}

class _StoreManagementSheetState extends ConsumerState<_StoreManagementSheet> {
  final _controller = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addStore() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isAdding = true);

    try {
      // Call repository directly for better control
      final repo = ref.read(listRepositoryProvider);
      await repo.addStore(name);
      _controller.clear();
      // Force refresh the stores list
      ref.invalidate(storesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "$name"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding store: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _deleteStore(String storeId, String storeName) async {
    try {
      final repo = ref.read(listRepositoryProvider);
      await repo.deleteStore(storeId);
      ref.invalidate(storesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "$storeName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting store: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Stores',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Enter store name...',
                        prefixIcon: const Icon(Icons.store_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addStore(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isAdding ? null : _addStore,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: storesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text('Error: $e')),
                ),
                data: (stores) {
                  if (stores.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No stores added yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add stores like "Costco" or "Whole Foods"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.store,
                            color: ThemeConfig.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          store.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: () => _deleteStore(store.id, store.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _EditItemSheet extends ConsumerStatefulWidget {
  final ListItem item;
  final List<Store> stores;
  final ListType listType;

  const _EditItemSheet({required this.item, required this.stores, required this.listType});

  @override
  ConsumerState<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends ConsumerState<_EditItemSheet> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late int _quantity;
  String? _selectedStore;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _quantity = widget.item.quantity;
    _selectedStore = widget.item.store;
    _selectedCategory = widget.item.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.item.copyWith(
      name: _nameController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      quantity: _quantity,
      store: _selectedStore,
      category: _selectedCategory,
    );

    await ref.read(listNotifierProvider.notifier).updateItem(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Quantity selector
              Row(
                children: [
                  const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
              // Store dropdown - only show for lists that support stores
              if (widget.listType != ListType.project) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStore,
                  decoration: InputDecoration(
                    labelText: 'Store',
                    prefixIcon: const Icon(Icons.store_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No store'),
                    ),
                    ...widget.stores.map((store) => DropdownMenuItem(
                          value: store.name,
                          child: Text(store.name),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStore = value);
                  },
                ),
              ],

              // Category/Aisle dropdown - only show for lists that support categories
              if (widget.listType != ListType.project) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: widget.listType == ListType.grocery ? 'Aisle' : 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(widget.listType == ListType.grocery ? 'No aisle' : 'No category'),
                    ),
                    ...(widget.listType == ListType.grocery ? Categories.all : ShoppingCategories.all)
                        .map((cat) => DropdownMenuItem(
                              value: cat.name,
                              child: Row(
                                children: [
                                  Text(cat.icon),
                                  const SizedBox(width: 8),
                                  Text(cat.name),
                                ],
                              ),
                            )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
