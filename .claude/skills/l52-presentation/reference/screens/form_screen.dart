// Template: Form screen with validation
//
// Location: lib/features/{feature}/presentation/screens/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature}/{feature} with feature name
// 3. Add/remove form fields as needed
// 4. Customize validation messages via i18n

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/strings.g.dart';
import '../providers/{feature}_form_notifier.dart';

/// {Feature} form screen for create operations.
///
/// Listens for success to pop back to previous screen.
final class {Feature}FormScreen extends ConsumerWidget {
  const {Feature}FormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({feature}FormNotifierProvider);
    final notifier = ref.read({feature}FormNotifierProvider.notifier);

    // Listen for success and pop
    ref.listen({feature}FormNotifierProvider, (prev, next) {
      if (next.isSuccess) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.{feature}.form.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field
            TextField(
              onChanged: notifier.updateTitle,
              decoration: InputDecoration(
                labelText: t.{feature}.form.titleLabel,
                hintText: t.{feature}.form.titleHint,
                errorText: state.titleError,
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Description field (expandable)
            Expanded(
              child: TextField(
                onChanged: notifier.updateDescription,
                decoration: InputDecoration(
                  labelText: t.{feature}.form.descriptionLabel,
                  hintText: t.{feature}.form.descriptionHint,
                  errorText: state.descriptionError,
                  alignLabelWithHint: true,
                ),
                autocorrect: false,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),

            // Error message
            if (state.submitError != null) ...[
              const SizedBox(height: 16),
              Text(
                state.submitError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 16),

            // Submit button
            FilledButton(
              onPressed: state.isSubmitting ? null : notifier.submit,
              child: state.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.common.save),
            ),
          ],
        ),
      ),
    );
  }
}
