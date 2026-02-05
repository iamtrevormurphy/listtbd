import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/config/theme_config.dart';
import '../../core/constants/categories.dart';
import '../../data/models/list_item.dart';
import '../../data/models/shopping_list.dart' show ListType;
import '../../data/models/store.dart';

class SwipeableItem extends StatelessWidget {
  final ListItem item;
  final ListType listType;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final Function(String) onCategoryChanged;
  final Function(String?)? onStoreChanged;
  final List<Store>? stores;

  const SwipeableItem({
    super.key,
    required this.item,
    this.listType = ListType.grocery,
    required this.onArchive,
    required this.onDelete,
    required this.onTap,
    required this.onCategoryChanged,
    this.onStoreChanged,
    this.stores,
  });

  @override
  Widget build(BuildContext context) {
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

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            item.name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              decoration: item.isArchived ? TextDecoration.lineThrough : null,
              color: item.isArchived ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: _buildSubtitle(context),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.quantity > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'x${item.quantity}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ThemeConfig.primaryColor,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final parts = <Widget>[];

    // Show category/aisle as subdued text with emoji (only for non-project lists)
    if (item.category != null && listType != ListType.project) {
      final emoji = listType == ListType.grocery
          ? Categories.getEmoji(item.category!)
          : ShoppingCategories.getEmoji(item.category!);
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              item.category!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Show store if set (only for non-project lists)
    if (item.store != null && listType != ListType.project) {
      if (parts.isNotEmpty) {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '•',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        );
      }
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              item.store!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Show notes if present
    if (item.notes != null && item.notes!.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '•',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        );
      }
      parts.add(
        Flexible(
          child: Text(
            item.notes!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    if (parts.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: parts,
      ),
    );
  }
}
