// Template: Repository interface or implementation
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Repository Provider Registration
// Register repository in lib/core/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../features/tasks/data/repositories/tasks_repository_impl.dart';
import '../features/tasks/domain/repositories/tasks_repository.dart';

// Assuming Dio provider exists
final dioProvider = Provider<Dio>((ref) {
  // Configure Dio with base URL, interceptors, etc.
  return Dio(BaseOptions(baseUrl: 'https://api.example.com'));
});

/// Tasks repository provider.
/// Uses DioClient implementation. Override in tests with mock.
final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TasksRepositoryImpl(
    remoteDataSource: TasksRemoteDataSource(dio: dio),
  );
});

// -----------------------------------------------------
// For testing, override with mock:
// -----------------------------------------------------
// void main() {
//   testWidgets('...', (tester) async {
//     await tester.pumpWidget(
//       ProviderScope(
//         overrides: [
//           tasksRepositoryProvider.overrideWithValue(MockTasksRepository()),
//         ],
//         child: MyApp(),
//       ),
//     );
//   });
// }
