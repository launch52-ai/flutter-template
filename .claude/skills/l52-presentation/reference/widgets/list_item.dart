// Template: List item widget
//
// Location: lib/features/{feature}/presentation/widgets/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature}/{feature} with feature name
// 3. Replace {Entity} with domain entity name
// 4. Customize layout and displayed fields

import 'package:flutter/material.dart';

import '../../domain/entities/{entity}.dart';

/// {Feature} list item widget.
///
/// Reusable widget for displaying items in lists.
/// Receives callbacks for tap and optional delete actions.
final class {Feature}ListItem extends StatelessWidget {
  const {Feature}ListItem({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  final {Entity} item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Leading icon or avatar
      leading: const CircleAvatar(
        child: Icon(Icons.article_outlined),
      ),
      // Primary text
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Secondary text (optional)
      subtitle: item.description != null
          ? Text(
              item.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      // Trailing action
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: 'Delete',
            )
          : const Icon(Icons.chevron_right),
      // Tap handler
      onTap: onTap,
    );
  }
}
