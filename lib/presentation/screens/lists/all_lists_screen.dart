import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme_config.dart';
import '../../../data/models/shopping_list.dart';
import '../../providers/list_provider.dart';
import '../../widgets/animated_background.dart';
import '../home/home_screen.dart';
import 'create_list_screen.dart';
import 'edit_list_screen.dart';

class AllListsScreen extends ConsumerWidget {
  const AllListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allListsAsync = ref.watch(allListsProvider);

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Provisions header
              Container(
                color: Colors.white.withValues(alpha: 0.9),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Text(
                  'Provisions',
                  style: ThemeConfig.youngSerifStyle(
                    fontSize: 22,
                    color: ThemeConfig.textPrimary,
                  ),
                ),
              ),

              // My Lists subheader
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'My Lists',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

              // Lists
              Expanded(
                child: allListsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (lists) {
                    if (lists.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final list = lists[index];

                        return _ListCard(
                          list: list,
                          onTap: () {
                            ref.read(listNotifierProvider.notifier).switchList(list.id);
                            // Check if we can pop (came from HomeScreen) or need to navigate
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              // This is the initial screen - navigate to HomeScreen
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            }
                          },
                          onEdit: () => _navigateToEdit(context, list),
                          onDelete: lists.length > 1
                              ? () => _confirmDelete(context, ref, list)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),

              // Create button
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create New List'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              Icons.checklist_rounded,
              size: 64,
              color: ThemeConfig.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No lists yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ThemeConfig.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first shopping list',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeConfig.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context, ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditListScreen(list: list),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List?'),
        content: Text(
          'Are you sure you want to delete "${list.name}"? This will permanently delete all items in this list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(listNotifierProvider.notifier).deleteList(list.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: ThemeConfig.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ListCard({
    required this.list,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ThemeConfig.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon - uses list's custom icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  list.iconData,
                  color: ThemeConfig.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
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
                    if (list.description != null && list.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        list.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ThemeConfig.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow to indicate navigation
              Icon(
                Icons.chevron_right,
                color: ThemeConfig.textSecondary,
              ),

              // Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: ThemeConfig.textSecondary),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: ThemeConfig.error),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: ThemeConfig.error)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
