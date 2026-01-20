// Template: Detail screen with ID parameter
//
// Location: lib/features/{feature}/presentation/screens/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature}/{feature} with feature name
// 3. Customize detail content layout
// 4. Add edit/delete actions as needed

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/strings.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/{entity}.dart';
import '../providers/{feature}_detail_notifier.dart';
import '../providers/{feature}_detail_state.dart';

/// {Feature} detail screen.
///
/// Receives ID as constructor parameter from router.
final class {Feature}DetailScreen extends ConsumerWidget {
  const {Feature}DetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({feature}DetailNotifierProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.{feature}.detail.title),
        actions: [
          // Show edit button only when loaded
          if (state is {Feature}DetailStateLoaded)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/{feature}/$id/edit'),
            ),
        ],
      ),
      body: switch (state) {
        {Feature}DetailStateInitial() || {Feature}DetailStateLoading() =>
          const Center(child: CircularProgressIndicator()),
        {Feature}DetailStateLoaded(:final item) =>
          _{Feature}DetailContent(item: item),
        {Feature}DetailStateNotFound() => EmptyState(
            icon: Icons.search_off,
            message: t.{feature}.notFound,
          ),
        {Feature}DetailStateError(:final message) => EmptyState(
            icon: Icons.error_outline,
            message: message,
          ),
      },
    );
  }
}

/// Private widget for detail content.
///
/// Extracted for readability when content is complex.
final class _{Feature}DetailContent extends StatelessWidget {
  const _{Feature}DetailContent({required this.item});

  final {Entity} item;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Access notifier through ProviderScope
        // This is a simplified example - actual implementation
        // would need to pass ref or use a different pattern
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            // Metadata (date, etc.)
            Text(
              _formatDate(item.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            // Content (if applicable)
            if (item.description != null) ...[
              const SizedBox(height: 24),
              Text(item.description!),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
