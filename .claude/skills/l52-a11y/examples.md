# Accessibility Examples

Complete Flutter code examples for common accessibility patterns.

---

## 1. Accessible Image Gallery

```dart
final class PhotoGallery extends StatelessWidget {
  final List<Photo> photos;

  const PhotoGallery({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _PhotoTile(
          photo: photo,
          onTap: () => _openPhoto(context, photo),
          onDelete: () => _confirmDelete(context, photo),
        );
      },
    );
  }
}

final class _PhotoTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoTile({
    required this.photo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Comprehensive label for screen readers
      label: _buildLabel(),
      button: true,
      onTap: onTap,
      onLongPress: onDelete,
      customSemanticsActions: {
        CustomSemanticsAction(label: t.common.delete): onDelete,
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with semantic label
            Image.network(
              photo.url,
              fit: BoxFit.cover,
              semanticLabel: photo.description ?? 'Photo ${photo.id}',
            ),
            // Selection indicator (excluded - redundant with semantics)
            if (photo.isSelected)
              ExcludeSemantics(
                child: Container(
                  color: Colors.blue.withOpacity(0.3),
                  child: const Icon(Icons.check_circle, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildLabel() {
    final parts = <String>[];

    if (photo.description != null) {
      parts.add(photo.description!);
    } else {
      parts.add('Photo');
    }

    if (photo.isSelected) {
      parts.add('selected');
    }

    parts.add('Double tap to view, long press for options');

    return parts.join(', ');
  }
}
```

---

## 2. Accessible Form

```dart
final class AccessibleForm extends ConsumerStatefulWidget {
  const AccessibleForm({super.key});

  @override
  ConsumerState<AccessibleForm> createState() => _AccessibleFormState();
}

final class _AccessibleFormState extends ConsumerState<AccessibleForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field with proper accessibility
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: TextField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: t.auth.email,
                hintText: 'name@example.com',
                errorText: _emailError,
                // Error icon for non-color indication
                suffixIcon: _emailError != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
              ),
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
          ),

          const SizedBox(height: 16),

          // Password field
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: t.auth.password,
                errorText: _passwordError,
                suffixIcon: _passwordError != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),

          const SizedBox(height: 24),

          // Submit button with loading state
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: Consumer(
              builder: (context, ref, _) {
                final isLoading = ref.watch(authProvider).isLoading;

                return Semantics(
                  button: true,
                  enabled: !isLoading,
                  label: t.auth.signIn,
                  hint: isLoading ? t.common.loading : null,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.auth.signIn),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    // Validate and announce errors
    final errors = _validate();

    if (errors.isNotEmpty) {
      // Announce first error to screen reader
      SemanticsService.announce(
        errors.values.first,
        TextDirection.ltr,
      );

      // Focus the first error field
      if (errors.containsKey('email')) {
        _emailFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
    }
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      errors['email'] = t.validation.required(field: t.auth.email);
    } else if (!email.contains('@')) {
      errors['email'] = t.validation.invalidEmail;
    }

    if (password.length < 8) {
      errors['password'] = t.validation.passwordTooShort;
    }

    setState(() {
      _emailError = errors['email'];
      _passwordError = errors['password'];
    });

    return errors;
  }
}
```

---

## 3. Accessible List with Actions

```dart
final class AccessibleTaskList extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task) onToggle;
  final void Function(Task) onDelete;

  const AccessibleTaskList({
    super.key,
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _EmptyState();
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => _TaskTile(
        task: tasks[index],
        onToggle: () => onToggle(tasks[index]),
        onDelete: () => onDelete(tasks[index]),
      ),
    );
  }
}

final class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        // Announce action to screen reader
        SemanticsService.announce(
          t.tasks.deletedAnnouncement(task: task.title),
          TextDirection.ltr,
        );
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: Semantics(
        // Combine all info into single announcement
        label: _buildLabel(),
        // Custom actions for screen reader users
        customSemanticsActions: {
          CustomSemanticsAction(label: t.tasks.markComplete): onToggle,
          CustomSemanticsAction(label: t.common.delete): onDelete,
        },
        child: ListTile(
          leading: Checkbox(
            value: task.isComplete,
            onChanged: (_) => onToggle(),
          ),
          title: Text(
            task.title,
            style: task.isComplete
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: task.dueDate != null
              ? Text(t.tasks.dueDate(date: task.dueDate!))
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: t.common.delete,
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }

  String _buildLabel() {
    final parts = <String>[task.title];

    if (task.isComplete) {
      parts.add('completed');
    } else {
      parts.add('not completed');
    }

    if (task.dueDate != null) {
      parts.add('due ${task.dueDate}');
    }

    return parts.join(', ');
  }
}

final class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Live region announces when list becomes empty
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.tasks.empty.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.tasks.empty.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. Accessible Custom Slider

```dart
final class AccessibleRatingSlider extends StatelessWidget {
  final double rating;
  final int maxRating;
  final ValueChanged<double> onChanged;

  const AccessibleRatingSlider({
    super.key,
    required this.rating,
    this.maxRating = 5,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: t.rating.label,
      value: t.rating.value(current: rating.round(), max: maxRating),
      increasedValue: rating < maxRating
          ? t.rating.value(current: (rating + 1).round(), max: maxRating)
          : null,
      decreasedValue: rating > 0
          ? t.rating.value(current: (rating - 1).round(), max: maxRating)
          : null,
      onIncrease: rating < maxRating ? () => onChanged(rating + 1) : null,
      onDecrease: rating > 0 ? () => onChanged(rating - 1) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxRating, (index) {
          return GestureDetector(
            onTap: () => onChanged(index + 1.0),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ExcludeSemantics(
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
```

---

## 5. Accessible Tab Bar

```dart
final class AccessibleTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<TabItem> tabs;
  final ValueChanged<int> onTabSelected;

  const AccessibleTabBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Indicate this is a tab list
      explicitChildNodes: true,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: Semantics(
              role: SemanticsRole.tab,
              selected: isSelected,
              label: tab.label,
              hint: isSelected
                  ? t.tabs.currentTab
                  : t.tabs.switchTo(tab: tab.label),
              child: InkWell(
                onTap: () => onTabSelected(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(child: Icon(tab.icon)),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

final class TabItem {
  final IconData icon;
  final String label;

  const TabItem({required this.icon, required this.label});
}
```

---

## 6. Accessible Status Updates

```dart
final class UploadProgressWidget extends StatelessWidget {
  final UploadState state;

  const UploadProgressWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Live region announces changes automatically
      liveRegion: true,
      // Use alert role for important status changes
      role: state is UploadError ? SemanticsRole.alert : SemanticsRole.status,
      label: _buildStatusLabel(),
      child: _buildStatusWidget(context),
    );
  }

  String _buildStatusLabel() {
    return switch (state) {
      UploadIdle() => t.upload.ready,
      UploadInProgress(:final progress) =>
        t.upload.progress(percent: (progress * 100).round()),
      UploadComplete() => t.upload.complete,
      UploadError(:final message) => t.upload.error(message: message),
    };
  }

  Widget _buildStatusWidget(BuildContext context) {
    return switch (state) {
      UploadIdle() => Text(t.upload.ready),
      UploadInProgress(:final progress) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(t.upload.progress(percent: (progress * 100).round())),
          ],
        ),
      UploadComplete() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(t.upload.complete),
          ],
        ),
      UploadError(:final message) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
    };
  }
}

sealed class UploadState {
  const UploadState();
}

final class UploadIdle extends UploadState {
  const UploadIdle();
}

final class UploadInProgress extends UploadState {
  final double progress;
  const UploadInProgress(this.progress);
}

final class UploadComplete extends UploadState {
  const UploadComplete();
}

final class UploadError extends UploadState {
  final String message;
  const UploadError(this.message);
}
```

---

## 7. Accessible Settings Screen

```dart
final class AccessibleSettingsScreen extends StatelessWidget {
  const AccessibleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(t.settings.title),
        ),
      ),
      body: ListView(
        children: [
          // Section header
          _SectionHeader(title: t.settings.appearance),

          // Theme toggle
          _SettingsTile(
            icon: Icons.dark_mode,
            title: t.settings.darkMode,
            trailing: Consumer(
              builder: (context, ref, _) {
                final isDark = ref.watch(themeProvider) == ThemeMode.dark;
                return Switch(
                  value: isDark,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).setDarkMode(value);
                    // Announce change
                    SemanticsService.announce(
                      value ? t.settings.darkModeOn : t.settings.darkModeOff,
                      TextDirection.ltr,
                    );
                  },
                );
              },
            ),
          ),

          // Navigation tile
          _SettingsTile(
            icon: Icons.notifications,
            title: t.settings.notifications,
            onTap: () => context.push('/settings/notifications'),
            trailing: const Icon(Icons.chevron_right),
          ),

          _SectionHeader(title: t.settings.account),

          // Destructive action
          _SettingsTile(
            icon: Icons.logout,
            title: t.settings.signOut,
            isDestructive: true,
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.settings.signOutConfirm.title),
        content: Text(t.settings.signOutConfirm.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Perform sign out
            },
            child: Text(
              t.settings.signOut,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
        ),
      ),
    );
  }
}

final class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : null;

    return MergeSemantics(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
```

---

## 8. Text Scaling Support

```dart
final class ScalableWidget extends StatelessWidget {
  const ScalableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return Padding(
      // Scale padding with text
      padding: EdgeInsets.all(textScaler.scale(16)),
      child: Row(
        children: [
          // Scale icon with text
          Icon(Icons.info, size: textScaler.scale(24)),
          SizedBox(width: textScaler.scale(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text automatically scales
                Text(
                  t.info.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: textScaler.scale(4)),
                Text(
                  t.info.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Button with scaled touch target
          SizedBox(
            width: textScaler.scale(48),
            height: textScaler.scale(48),
            child: IconButton(
              icon: Icon(Icons.close, size: textScaler.scale(24)),
              tooltip: t.common.close,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 9. Accessibility Test Examples

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoGallery accessibility', () {
    testWidgets('meets all guidelines', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PhotoGallery(photos: [testPhoto]),
      ));

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('photo has correct semantics', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PhotoGallery(photos: [testPhoto]),
      ));

      final semantics = tester.getSemantics(find.byType(_PhotoTile).first);

      expect(
        semantics,
        matchesSemantics(
          label: contains('Beach sunset'),
          hasTapAction: true,
          hasLongPressAction: true,
        ),
      );
    });

    testWidgets('supports text scaling', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            home: PhotoGallery(photos: [testPhoto]),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
```

---

## Summary

| Pattern | Key Accessibility Features |
|---------|---------------------------|
| **Image Gallery** | Semantic labels, custom actions, selection state |
| **Form** | Focus order, error announcements, field labels |
| **Task List** | Combined labels, dismissible actions, empty state |
| **Custom Slider** | Semantic slider role, increase/decrease actions |
| **Tab Bar** | Tab role, selection state, navigation hints |
| **Status Updates** | Live regions, alert role for errors |
| **Settings** | Section headers, merged semantics, destructive hints |
| **Scalable Widget** | Text scaler for all dimensions |
