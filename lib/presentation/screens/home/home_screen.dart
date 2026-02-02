import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/categories.dart';
import '../../../data/models/list_item.dart';
import '../../../data/models/repurchase_suggestion.dart';
import '../../../services/ai_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/list_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../widgets/quick_add_bar.dart';
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
      data: (list) => _HomeContent(listId: list.id),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final String listId;

  const _HomeContent({required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(activeItemsProvider(listId));
    final suggestionsAsync = ref.watch(suggestionsProvider);
    final listNotifier = ref.read(listNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
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
              }
            },
            itemBuilder: (context) => [
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
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (items) {
                final suggestions = suggestionsAsync.valueOrNull ?? [];

                if (items.isEmpty && suggestions.isEmpty) {
                  return const _EmptyState();
                }

                final grouped = ref.watch(groupedItemsProvider(items));
                return _ContentList(
                  suggestions: suggestions,
                  groupedItems: grouped,
                  onAddSuggestion: (s) => _addSuggestion(context, ref, s),
                  onDismissSuggestion: (s) => _dismissSuggestion(ref, s),
                  onArchive: (item) => _archiveItem(context, ref, item),
                  onDelete: (item) => _deleteItem(context, ref, item),
                  onTap: (item) => _editItem(context, ref, item),
                  onCategoryChanged: (item, category) async {
                    await listNotifier.updateCategory(item.id, category);
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
    );
  }

  Future<void> _addItem(WidgetRef ref, String name) async {
    final notifier = ref.read(listNotifierProvider.notifier);

    // Add item first (appears immediately with no category)
    final item = await notifier.addItem(listId: listId, name: name);

    if (item != null) {
      // Then categorize in background using AI
      final aiService = AIService();
      final result = await aiService.categorizeItem(name);

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

  void _deleteItem(BuildContext context, WidgetRef ref, ListItem item) {
    ref.read(listNotifierProvider.notifier).deleteItem(item.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} deleted'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _editItem(BuildContext context, WidgetRef ref, ListItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditItemSheet(item: item),
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
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your list is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
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

class _ContentList extends StatelessWidget {
  final List<RepurchaseSuggestion> suggestions;
  final Map<String, List<ListItem>> groupedItems;
  final Function(RepurchaseSuggestion) onAddSuggestion;
  final Function(RepurchaseSuggestion) onDismissSuggestion;
  final Function(ListItem) onArchive;
  final Function(ListItem) onDelete;
  final Function(ListItem) onTap;
  final Function(ListItem, String) onCategoryChanged;

  const _ContentList({
    required this.suggestions,
    required this.groupedItems,
    required this.onAddSuggestion,
    required this.onDismissSuggestion,
    required this.onArchive,
    required this.onDelete,
    required this.onTap,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
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

        // Grouped items
        ...groupedItems.entries.map((entry) {
          final category = entry.key;
          final items = entry.value;
          final emoji = Categories.getEmoji(category);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${items.length})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              ...items.map((item) => SwipeableItem(
                    item: item,
                    onArchive: () => onArchive(item),
                    onDelete: () => onDelete(item),
                    onTap: () => onTap(item),
                    onCategoryChanged: (cat) => onCategoryChanged(item, cat),
                  )),
            ],
          );
        }),
      ],
    );
  }
}

class _EditItemSheet extends ConsumerStatefulWidget {
  final ListItem item;

  const _EditItemSheet({required this.item});

  @override
  ConsumerState<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends ConsumerState<_EditItemSheet> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _quantity = widget.item.quantity;
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
        child: Padding(
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
                decoration: const InputDecoration(
                  labelText: 'Item name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Quantity:'),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
