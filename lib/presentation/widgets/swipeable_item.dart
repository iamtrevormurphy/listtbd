import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/config/theme_config.dart';
import '../../core/constants/categories.dart';
import '../../data/models/list_item.dart';

class SwipeableItem extends StatelessWidget {
  final ListItem item;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final Function(String) onCategoryChanged;

  const SwipeableItem({
    super.key,
    required this.item,
    required this.onArchive,
    required this.onDelete,
    required this.onTap,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categoryEmoji = item.category != null
        ? Categories.getEmoji(item.category!)
        : '';

    return Slidable(
      key: ValueKey(item.id),

      // Swipe right to archive
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        dismissible: DismissiblePane(
          onDismissed: () {
            HapticFeedback.mediumImpact();
            onArchive();
          },
        ),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              onArchive();
            },
            backgroundColor: ThemeConfig.archiveColor,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Done',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          ),
        ],
      ),

      // Swipe left to delete
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        dismissible: DismissiblePane(
          onDismissed: () {
            HapticFeedback.mediumImpact();
            onDelete();
          },
        ),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              onDelete();
            },
            backgroundColor: ThemeConfig.deleteColor,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
          ),
        ],
      ),

      child: ListTile(
        onTap: onTap,
        leading: Text(
          categoryEmoji,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isArchived ? TextDecoration.lineThrough : null,
            color: item.isArchived ? Colors.grey : null,
          ),
        ),
        subtitle: item.notes != null && item.notes!.isNotEmpty
            ? Text(
                item.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.quantity > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'x${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            _CategoryChip(
              category: item.category,
              onTap: () => _showCategoryPicker(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: Categories.all.length,
                itemBuilder: (context, index) {
                  final category = Categories.all[index];
                  final isSelected = item.category == category.name;
                  return ListTile(
                    leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
                    title: Text(category.name),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      Navigator.pop(context);
                      onCategoryChanged(category.name);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String? category;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
    }

    final color = ThemeConfig.aisleColors[category] ?? Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          category!,
          style: TextStyle(
            fontSize: 12,
            color: color.computeLuminance() > 0.5
                ? Colors.black87
                : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}
