import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme_config.dart';
import '../../../data/models/shopping_list.dart';
import '../../providers/list_provider.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/icon_picker.dart';
import '../home/home_screen.dart';

class CreateListScreen extends ConsumerStatefulWidget {
  const CreateListScreen({super.key});

  @override
  ConsumerState<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends ConsumerState<CreateListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedIcon = 'checklist';
  ListType _selectedType = ListType.grocery;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final notifier = ref.read(listNotifierProvider.notifier);
    final newList = await notifier.createList(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      icon: _selectedIcon,
      type: _selectedType.name,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (newList != null) {
      // Switch to the new list (this saves the preference)
      notifier.switchList(newList.id);
      // Navigate to HomeScreen, clearing the stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create list'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickIcon() async {
    final iconId = await showIconPicker(context, currentIcon: _selectedIcon);
    if (iconId != null) {
      setState(() => _selectedIcon = iconId);
    }
  }

  IconData get _currentIconData {
    final option = ShoppingList.availableIcons.firstWhere(
      (o) => o.id == _selectedIcon,
      orElse: () => ShoppingList.availableIcons.first,
    );
    return option.icon;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'New List',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _createList,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon picker
                        Center(
                          child: GestureDetector(
                            onTap: _pickIcon,
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: ThemeConfig.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ThemeConfig.primaryColor.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    _currentIconData,
                                    size: 40,
                                    color: ThemeConfig.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to change icon',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ThemeConfig.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Name field
                        Text(
                          'List Name',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: ThemeConfig.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'e.g., Weekly Groceries, Trip Supplies',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: ThemeConfig.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: ThemeConfig.border),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a name for your list';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Description field
                        Text(
                          'Description (optional)',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: ThemeConfig.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'What is this list for?',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: ThemeConfig.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: ThemeConfig.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // List type selector
                        Text(
                          'List Type',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: ThemeConfig.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<ListType>(
                          segments: ListType.values.map((type) {
                            return ButtonSegment<ListType>(
                              value: type,
                              label: Text(type.displayName),
                              icon: Icon(type.icon),
                            );
                          }).toList(),
                          selected: {_selectedType},
                          onSelectionChanged: (Set<ListType> selected) {
                            setState(() => _selectedType = selected.first);
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return ThemeConfig.primaryColor.withValues(alpha: 0.15);
                              }
                              return Colors.white;
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ThemeConfig.primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ThemeConfig.primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedType.icon,
                                size: 20,
                                color: ThemeConfig.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedType.description,
                                  style: TextStyle(
                                    color: ThemeConfig.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Tips
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ThemeConfig.secondaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 20,
                                    color: ThemeConfig.secondaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ideas for lists',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: ThemeConfig.secondaryDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTip('Weekly grocery shopping'),
                              _buildTip('Party supplies'),
                              _buildTip('Camping trip essentials'),
                              _buildTip('Holiday gift shopping'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: ThemeConfig.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: ThemeConfig.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
