import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/categories.dart';
import '../../../data/models/list_item.dart';
import '../../providers/list_provider.dart';

class ArchiveScreen extends ConsumerWidget {
  final String listId;

  const ArchiveScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedItemsProvider(listId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
      ),
      body: archivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyArchive();
          }

          // Group by date
          final groupedByDate = _groupByDate(items);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedByDate.length,
            itemBuilder: (context, index) {
              final date = groupedByDate.keys.elementAt(index);
              final dateItems = groupedByDate[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _formatDate(date),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...dateItems.map((item) => _ArchivedItemTile(
                        item: item,
                        onRestore: () => _restoreItem(context, ref, item),
                        onDelete: () => _deleteItem(context, ref, item),
                      )),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<ListItem>> _groupByDate(List<ListItem> items) {
    final grouped = <DateTime, List<ListItem>>{};

    for (final item in items) {
      final date = item.archivedAt ?? item.updatedAt;
      final dateOnly = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dateOnly, () => []).add(item);
    }

    // Sort by date descending
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  void _restoreItem(BuildContext context, WidgetRef ref, ListItem item) {
    ref.read(listNotifierProvider.notifier).unarchiveItem(item.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} restored to list')),
    );
  }

  void _deleteItem(BuildContext context, WidgetRef ref, ListItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Are you sure you want to permanently delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(listNotifierProvider.notifier).deleteItem(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} deleted permanently')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No archived items',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe right on items to archive them',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedItemTile extends StatelessWidget {
  final ListItem item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _ArchivedItemTile({
    required this.item,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = item.category != null ? Categories.getEmoji(item.category!) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(
          item.name,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey,
          ),
        ),
        subtitle: item.archivedAt != null
            ? Text(
                'Completed ${DateFormat.jm().format(item.archivedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Restore to list',
              onPressed: onRestore,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete permanently',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
