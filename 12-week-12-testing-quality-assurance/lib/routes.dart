import 'package:go_router/go_router.dart';

import 'core/format.dart';
import 'features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'features/notes/presentation/pages/note_detail_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/performance/presentation/pages/performance_benchmark_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';

class AppRoutes {
  static const home = '/';
  static const noteDetail = '/note/:id';
  static const settings = '/settings';
  static const aiChat = '/ai-chat';
  static const performanceBenchmark = '/performance';
}

/// Aktifkan dengan `--dart-define=BENCHMARK_MODE=true` saat profiling.
const bool kBenchmarkAtStartup = bool.fromEnvironment('BENCHMARK_MODE');

final appRouter = GoRouter(
  initialLocation: kBenchmarkAtStartup
      ? AppRoutes.performanceBenchmark
      : AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const NotesPage(),
    ),
    GoRoute(
      path: AppRoutes.noteDetail,
      builder: (context, state) {
        final id = parseRouteId(state.pathParameters['id']);
        return NoteDetailPage(id: id);
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.aiChat,
      builder: (context, state) => const AiChatPage(),
    ),
    GoRoute(
      path: AppRoutes.performanceBenchmark,
      builder: (context, state) => const PerformanceBenchmarkPage(),
    ),
  ],
);
