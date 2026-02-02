import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/categories.dart';
import '../../data/models/repurchase_suggestion.dart';

class SuggestionCard extends StatelessWidget {
  final RepurchaseSuggestion suggestion;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAdd,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = suggestion.category != null
        ? Categories.getEmoji(suggestion.category!)
        : '📦';

    final daysSince = suggestion.daysSinceLastPurchase;
    final isOverdue = suggestion.isOverdue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isOverdue
          ? Colors.orange.shade50
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: isOverdue ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOverdue ? 'Time to restock!' : 'Running low?',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.orange.shade700 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _buildSubtitle(daysSince),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                FilledButton.tonal(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Add'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(int daysSince) {
    if (suggestion.lastPurchasedAt == null) {
      return 'Based on your purchase history';
    }

    final lastDate = DateFormat.MMMd().format(suggestion.lastPurchasedAt!);

    if (daysSince == 0) {
      return 'Last purchased today';
    } else if (daysSince == 1) {
      return 'Last purchased yesterday';
    } else if (daysSince < 7) {
      return 'Last purchased $daysSince days ago';
    } else if (daysSince < 30) {
      final weeks = daysSince ~/ 7;
      return 'Last purchased $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return 'Last purchased on $lastDate';
    }
  }
}

/// Horizontal scrollable list of suggestion cards
class SuggestionsList extends StatelessWidget {
  final List<RepurchaseSuggestion> suggestions;
  final Function(RepurchaseSuggestion) onAdd;
  final Function(RepurchaseSuggestion) onDismiss;

  const SuggestionsList({
    super.key,
    required this.suggestions,
    required this.onAdd,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Suggestions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${suggestions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...suggestions.take(3).map((suggestion) => SuggestionCard(
              suggestion: suggestion,
              onAdd: () => onAdd(suggestion),
              onDismiss: () => onDismiss(suggestion),
            )),
        if (suggestions.length > 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '+ ${suggestions.length - 3} more suggestions',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        const Divider(),
      ],
    );
  }
}
