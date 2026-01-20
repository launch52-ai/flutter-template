# Design Examples

Complete Flutter implementation patterns for common UX scenarios.

---

## 1. Login Screen with Auto-Focus

A well-designed login screen demonstrates multiple UX principles:

```dart
final class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

final class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    // Auto-focus email field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocus.requestFocus();
    });
  }

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
    return GestureDetector(
      // Tap outside to dismiss keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            // Handle keyboard appearance
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 48),

                // Title
                Text(
                  t.auth.login.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 8),
                Text(
                  t.auth.login.subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 48),

                // Email field
                TextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  decoration: InputDecoration(
                    labelText: t.auth.email,
                    hintText: 'name@example.com',
                    errorText: _errors['email'],
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  onSubmitted: (_) => _handleSubmit(),
                  decoration: InputDecoration(
                    labelText: t.auth.password,
                    errorText: _errors['password'],
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                ),
                SizedBox(height: 8),

                // Forgot password link (in easy reach zone)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(t.auth.forgotPassword),
                  ),
                ),
                SizedBox(height: 24),

                // Primary CTA - at bottom, full width, thumb-friendly
                Consumer(
                  builder: (context, ref, _) {
                    final state = ref.watch(authNotifierProvider);
                    final isLoading = state.isLoading;

                    return LoadingButton(
                      label: t.auth.signIn,
                      isLoading: isLoading,
                      onPressed: _handleSubmit,
                    );
                  },
                ),
                SizedBox(height: 16),

                // Secondary action
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text(t.auth.noAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Validate
    final errors = <String, String>{};

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      errors['email'] = t.validation.required(field: t.auth.email);
    } else if (!email.contains('@')) {
      errors['email'] = t.validation.invalidEmail;
    }

    if (password.isEmpty) {
      errors['password'] = t.validation.required(field: t.auth.password);
    } else if (password.length < 8) {
      errors['password'] = t.validation.passwordTooShort;
    }

    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      // Focus first error field
      HapticFeedback.mediumImpact();
      if (errors.containsKey('email')) {
        _emailFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
      return;
    }

    // Clear errors and submit
    setState(() => _errors = {});

    final result = await ref.read(authNotifierProvider.notifier).signIn(
      email: email,
      password: password,
    );

    result.when(
      success: (_) {
        HapticFeedback.mediumImpact();
        context.go('/dashboard');
      },
      error: (message) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errors = {'email': message};
        });
        _emailFocus.requestFocus();
      },
    );
  }
}
```

---

## 2. List with Pull to Refresh & Skeleton Loading

```dart
final class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.feed.title)),
      body: feedAsync.when(
        loading: () => _buildSkeleton(),
        error: (error, _) => _buildError(context, ref, error),
        data: (items) => items.isEmpty
            ? _buildEmpty(context)
            : _buildList(context, ref, items),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (_, index) => _SkeletonItem(),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              t.feed.error.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              t.feed.error.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(feedProvider),
              icon: Icon(Icons.refresh),
              label: Text(t.common.buttons.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              t.feed.empty.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              t.feed.empty.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<FeedItem> items) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await ref.read(feedProvider.notifier).refresh();
      },
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _FeedItemTile(
            item: item,
            onTap: () => context.push('/feed/${item.id}'),
            onDelete: () => _confirmDelete(context, ref, item),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FeedItem item,
  ) async {
    final confirmed = await showConfirmation(
      context,
      title: t.feed.deleteConfirm.title,
      message: t.feed.deleteConfirm.message,
      confirmLabel: t.common.buttons.delete,
      cancelLabel: t.common.buttons.cancel,
      isDestructive: true,
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      await ref.read(feedProvider.notifier).delete(item.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.feed.itemDeleted),
            action: SnackBarAction(
              label: t.common.buttons.undo,
              onPressed: () {
                ref.read(feedProvider.notifier).restore(item);
              },
            ),
          ),
        );
      }
    }
  }
}

final class _SkeletonItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar skeleton
          ShimmerBox(width: 48, height: 48, circular: true),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 16),
                SizedBox(height: 8),
                ShimmerBox(width: 150, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _FeedItemTile extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FeedItemTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true; // Or show confirmation
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: item.imageUrl != null
              ? NetworkImage(item.imageUrl!)
              : null,
          child: item.imageUrl == null
              ? Text(item.title[0].toUpperCase())
              : null,
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }
}
```

---

## 3. Form with Inline Validation

```dart
final class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

final class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  final _nameFocus = FocusNode();
  final _bioFocus = FocusNode();

  String? _nameError;
  int _bioCharCount = 0;
  static const _maxBioLength = 150;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _bioCharCount = _bioController.text.length;

    // Listen for changes
    _nameController.addListener(_onChanged);
    _bioController.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardDialog() ?? false;
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.profile.edit.title),
          actions: [
            TextButton(
              onPressed: _hasChanges ? _handleSave : null,
              child: Text(t.common.buttons.save),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field with blur validation
              TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _bioFocus.requestFocus(),
                onEditingComplete: () {
                  _validateName();
                  _bioFocus.requestFocus();
                },
                decoration: InputDecoration(
                  labelText: t.profile.name,
                  hintText: t.profile.nameHint,
                  errorText: _nameError,
                  counterText: '', // Hide counter
                ),
                maxLength: 50,
              ),
              SizedBox(height: 16),

              // Bio field with character count
              TextField(
                controller: _bioController,
                focusNode: _bioFocus,
                maxLines: 4,
                maxLength: _maxBioLength,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  setState(() => _bioCharCount = value.length);
                },
                decoration: InputDecoration(
                  labelText: t.profile.bio,
                  hintText: t.profile.bioHint,
                  alignLabelWithHint: true,
                  helperText: t.profile.bioHelper,
                  counterText: '$_bioCharCount/$_maxBioLength',
                  counterStyle: TextStyle(
                    color: _bioCharCount > _maxBioLength * 0.9
                        ? AppColors.warning
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _validateName() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _nameError = t.validation.required(field: t.profile.name);
      } else if (name.length < 2) {
        _nameError = t.validation.tooShort(field: t.profile.name, min: 2);
      } else {
        _nameError = null;
      }
    });
  }

  Future<bool?> _showDiscardDialog() {
    return showConfirmation(
      context,
      title: t.common.dialogs.discardChanges.title,
      message: t.common.dialogs.discardChanges.message,
      confirmLabel: t.common.dialogs.discardChanges.confirm,
      cancelLabel: t.common.dialogs.discardChanges.cancel,
      isDestructive: true,
    );
  }

  Future<void> _handleSave() async {
    _validateName();

    if (_nameError != null) {
      HapticFeedback.mediumImpact();
      _nameFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();

    final result = await ref.read(userProfileProvider.notifier).update(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
    );

    result.when(
      success: (_) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.profile.saved)),
        );
        setState(() => _hasChanges = false);
        context.pop();
      },
      error: (message) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }
}
```

---

## 4. Search with Debounce

```dart
final class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

final class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: t.search.placeholder,
            border: InputBorder.none,
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _buildBody(searchResults, query),
    );
  }

  Widget _buildBody(AsyncValue<List<SearchResult>> results, String query) {
    if (query.isEmpty) {
      return _buildRecentSearches();
    }

    return results.when(
      loading: () => _buildLoadingIndicator(),
      error: (_, __) => _buildError(),
      data: (items) => items.isEmpty
          ? _buildNoResults(query)
          : _buildResults(items),
    );
  }

  Widget _buildRecentSearches() {
    final recent = ref.watch(recentSearchesProvider);

    if (recent.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              t.search.startTyping,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            t.search.recent,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...recent.map((query) => ListTile(
          leading: Icon(Icons.history),
          title: Text(query),
          onTap: () {
            _searchController.text = query;
            _onSearchChanged(query);
          },
        )),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    // Subtle loading - don't show full skeleton
    return LinearProgressIndicator();
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              t.search.noResults(query: query),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              t.search.noResultsHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(List<SearchResult> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: item.icon,
          title: Text(item.title),
          subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
          onTap: () {
            HapticFeedback.selectionClick();
            // Save to recent
            ref.read(recentSearchesProvider.notifier).add(item.title);
            context.push(item.route);
          },
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          SizedBox(height: 8),
          Text(t.search.error),
        ],
      ),
    );
  }
}
```

---

## 5. Bottom Sheet Modal with Drag Handle

```dart
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isDismissible = true,
  bool enableDrag = true,
  double initialSize = 0.5,
  double maxSize = 0.9,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.25,
      maxChildSize: maxSize,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Drag handle
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevent tap through
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Usage
void _showOptions(BuildContext context) {
  showAppBottomSheet(
    context: context,
    child: Column(
      children: [
        ListTile(
          leading: Icon(Icons.edit),
          title: Text(t.common.edit),
          onTap: () {
            Navigator.pop(context);
            _edit();
          },
        ),
        ListTile(
          leading: Icon(Icons.share),
          title: Text(t.common.share),
          onTap: () {
            Navigator.pop(context);
            _share();
          },
        ),
        ListTile(
          leading: Icon(Icons.delete, color: AppColors.error),
          title: Text(
            t.common.delete,
            style: TextStyle(color: AppColors.error),
          ),
          onTap: () {
            Navigator.pop(context);
            _delete();
          },
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    ),
  );
}
```

---

## 6. Loading Button Component

```dart
final class LoadingButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

final class _LoadingButtonState extends State<LoadingButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onTap: _enabled
          ? () {
              HapticFeedback.mediumImpact();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 100),
        opacity: _pressed ? 0.7 : (_enabled ? 1.0 : 0.5),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.isPrimary
                ? null
                : Border.all(color: AppColors.primary),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: widget.isPrimary
                          ? Colors.white
                          : AppColors.primary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.isPrimary
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.isPrimary
                              ? Colors.white
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
```

---

## 7. Shimmer Skeleton Components

```dart
final class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final bool circular;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.circular = false,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

final class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.circular ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circular
                ? null
                : widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * _controller.value, 0),
              end: Alignment(-0.5 + 2 * _controller.value, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

// Pre-built skeleton components
final class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: size, height: size, circular: true);
  }
}

final class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
  }
}

final class SkeletonListItem extends StatelessWidget {
  final bool hasAvatar;
  final int lines;

  const SkeletonListItem({
    super.key,
    this.hasAvatar = true,
    this.lines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (hasAvatar) ...[
            SkeletonAvatar(),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: double.infinity, height: 16),
                if (lines > 1) ...[
                  SizedBox(height: 8),
                  SkeletonText(width: 150, height: 12),
                ],
                if (lines > 2) ...[
                  SizedBox(height: 6),
                  SkeletonText(width: 100, height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Summary

| Pattern | Key UX Points |
|---------|---------------|
| Login | Auto-focus, keyboard flow, thumb-friendly CTA |
| List | Pull refresh, skeleton, swipe actions, empty state |
| Form | Blur validation, character count, discard warning |
| Search | Auto-focus, debounce, recent searches, no-results |
| Bottom sheet | Drag handle, swipe dismiss, safe area |
| Buttons | Press feedback, loading state, haptics |
| Skeletons | Match layout, shimmer animation, dark mode |
