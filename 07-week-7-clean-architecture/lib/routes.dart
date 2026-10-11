import 'package:go_router/go_router.dart';
import 'core/format.dart';
import 'features/notes/presentation/pages/note_detail_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';

class AppRoutes {
  static const home = '/';
  static const noteDetail = '/note/:id';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
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
  ],
);
