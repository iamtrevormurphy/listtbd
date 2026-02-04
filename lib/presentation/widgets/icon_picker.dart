import 'package:flutter/material.dart';

import '../../core/config/theme_config.dart';
import '../../data/models/shopping_list.dart';

class IconPicker extends StatelessWidget {
  final String? selectedIconId;
  final ValueChanged<String> onIconSelected;

  const IconPicker({
    super.key,
    this.selectedIconId,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: ShoppingList.availableIcons.length,
      itemBuilder: (context, index) {
        final option = ShoppingList.availableIcons[index];
        final isSelected = selectedIconId == option.id ||
            (selectedIconId == null && index == 0);

        return _IconOption(
          option: option,
          isSelected: isSelected,
          onTap: () => onIconSelected(option.id),
        );
      },
    );
  }
}

class _IconOption extends StatelessWidget {
  final ListIconOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _IconOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConfig.primaryColor
              : ThemeConfig.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ThemeConfig.primaryColor
                : ThemeConfig.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              option.icon,
              color: isSelected ? Colors.white : ThemeConfig.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : ThemeConfig.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows an icon picker in a bottom sheet and returns the selected icon ID
Future<String?> showIconPicker(BuildContext context, {String? currentIcon}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose Icon',
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
            const SizedBox(height: 16),
            IconPicker(
              selectedIconId: currentIcon,
              onIconSelected: (iconId) => Navigator.pop(context, iconId),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
