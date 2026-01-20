// Template: List screen with pattern matching
//
// Location: lib/features/{feature}/presentation/screens/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature}/{feature} with feature name
// 3. Customize empty state icon and message
// 4. Add FAB or other actions as needed

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/strings.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/{feature}_notifier.dart';
import '../providers/{feature}_state.dart';
import '../widgets/{feature}_list_item.dart';

/// {Feature} list screen.
///
/// Uses pattern matching on sealed state for exhaustive handling.
final class {Feature}Screen extends ConsumerWidget {
  const {Feature}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({feature}NotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.{feature}.title),
      ),
      // Optional: FAB for create action
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/{feature}/new'),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        // Initial and Loading show same indicator
        {Feature}StateInitial() || {Feature}StateLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        // Loaded state - handle empty case
        {Feature}StateLoaded(:final items) => items.isEmpty
            ? EmptyState(
                icon: Icons.inbox_outlined,
                message: t.{feature}.empty,
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read({feature}NotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return {Feature}ListItem(
                      item: item,
                      onTap: () => context.push('/{feature}/${item.id}'),
                      onDelete: () => ref
                          .read({feature}NotifierProvider.notifier)
                          .delete(item.id),
                    );
                  },
                ),
              ),
        // Error state
        {Feature}StateError(:final message) => EmptyState(
            icon: Icons.error_outline,
            message: message,
          ),
      },
    );
  }
}
