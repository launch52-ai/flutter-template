// Template: Optimistic update pattern
//
// Location: lib/core/data/optimistic/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Optimistic Updates
// Update UI immediately, then sync with server. Revert on failure.

// -----------------------------------------------------
// Basic Optimistic Update Example (Toggle Like):
// -----------------------------------------------------
//
// Future<void> toggleLike(String postId) async {
//   final currentState = state;
//   if (currentState is! PostsStateLoaded) return;
//
//   // Find the post
//   final postIndex = currentState.items.indexWhere((p) => p.id == postId);
//   if (postIndex == -1) return;
//
//   final post = currentState.items[postIndex];
//
//   // Optimistically update UI
//   final updatedPost = post.copyWith(
//     isLiked: !post.isLiked,
//     likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
//   );
//
//   final updatedItems = [...currentState.items];
//   updatedItems[postIndex] = updatedPost;
//   state = currentState.copyWith(items: updatedItems);
//
//   // Send to server
//   try {
//     await ref.read(postsRepositoryProvider).toggleLike(postId);
//   } catch (e) {
//     // Revert on error
//     final revertedItems = [...(state as PostsStateLoaded).items];
//     revertedItems[postIndex] = post; // Original post
//     state = (state as PostsStateLoaded).copyWith(items: revertedItems);
//
//     // Show error to user
//     ref.read(snackbarProvider.notifier).show(
//           'Could not update like. Please try again.',
//         );
//   }
// }

// -----------------------------------------------------
// Optimistic Delete with Undo Example:
// -----------------------------------------------------
//
// Future<void> deletePost(String postId) async {
//   final currentState = state;
//   if (currentState is! PostsStateLoaded) return;
//
//   // Find and remove post
//   final postIndex = currentState.items.indexWhere((p) => p.id == postId);
//   if (postIndex == -1) return;
//
//   final deletedPost = currentState.items[postIndex];
//   final updatedItems = currentState.items.where((p) => p.id != postId).toList();
//   state = currentState.copyWith(items: updatedItems);
//
//   // Show undo snackbar
//   final shouldRevert = await ref.read(snackbarProvider.notifier).showWithUndo(
//         'Post deleted',
//         duration: const Duration(seconds: 5),
//       );
//
//   if (shouldRevert) {
//     // Revert deletion
//     final currentItems = (state as PostsStateLoaded).items;
//     final revertedItems = [...currentItems];
//     revertedItems.insert(postIndex.clamp(0, revertedItems.length), deletedPost);
//     state = (state as PostsStateLoaded).copyWith(items: revertedItems);
//     return;
//   }
//
//   // Actually delete on server
//   try {
//     await ref.read(postsRepositoryProvider).deletePost(postId);
//   } catch (e) {
//     // Revert and show error
//     final currentItems = (state as PostsStateLoaded).items;
//     final revertedItems = [...currentItems];
//     revertedItems.insert(postIndex.clamp(0, revertedItems.length), deletedPost);
//     state = (state as PostsStateLoaded).copyWith(items: revertedItems);
//
//     ref.read(snackbarProvider.notifier).show('Could not delete post');
//   }
// }

// -----------------------------------------------------
// Key Points:
// -----------------------------------------------------
// 1. Save original state before optimistic update
// 2. Update UI immediately for instant feedback
// 3. Send request to server in background
// 4. On error, revert to original state
// 5. Show user-friendly error message
// 6. For deletes, consider undo period before actual deletion
