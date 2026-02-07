import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme_config.dart';
import '../../../data/models/shopping_list.dart';
import '../../providers/list_provider.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/icon_picker.dart';

class EditListScreen extends ConsumerStatefulWidget {
  final ShoppingList list;

  const EditListScreen({super.key, required this.list});

  @override
  ConsumerState<EditListScreen> createState() => _EditListScreenState();
}

class _EditListScreenState extends ConsumerState<EditListScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedIcon;
  late ListType _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list.name);
    _descriptionController = TextEditingController(text: widget.list.description ?? '');
    _selectedIcon = widget.list.icon ?? 'checklist';
    _selectedType = widget.list.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final notifier = ref.read(listNotifierProvider.notifier);
    final updated = await notifier.updateList(
      listId: widget.list.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      icon: _selectedIcon,
      type: _selectedType.name,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (updated != null) {
      Navigator.of(context).pop(updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update list'),
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
                        'Edit List',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _saveList,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
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
                            hintText: 'e.g., Weekly Groceries',
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
                        DropdownButtonFormField<ListType>(
                          initialValue: _selectedType,
                          decoration: InputDecoration(
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: ListType.values.map((type) {
                            return DropdownMenuItem<ListType>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    type.icon,
                                    size: 20,
                                    color: ThemeConfig.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          type.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          type.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ThemeConfig.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedType = value);
                            }
                          },
                          selectedItemBuilder: (context) {
                            return ListType.values.map((type) {
                              return Row(
                                children: [
                                  Icon(
                                    type.icon,
                                    size: 20,
                                    color: ThemeConfig.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    type.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
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
}
