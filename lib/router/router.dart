import 'package:go_router/go_router.dart';
import 'package:startbuddy/page/feedback.dart';
import 'package:startbuddy/page/help_support.dart';
import 'package:startbuddy/page/home.dart';
import 'package:startbuddy/page/loading.dart';
import 'package:startbuddy/page/login.dart';
import 'package:startbuddy/page/my_startups.dart';
import 'package:startbuddy/page/register.dart';
import 'package:startbuddy/page/settings.dart';
import 'package:startbuddy/page/workspace.dart';
import 'package:startbuddy/service/auth/auth_service.dart';

final AuthService _auth = AuthService();

final GoRouter router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  refreshListenable: _auth.authNotifier,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/validate',
      builder: (context, state) {
        final extra = state.extra;
        final prompt = extra is String
            ? extra
            : state.uri.queryParameters['prompt'] ?? '';
        return LoadingPage(prompt: prompt);
      },
    ),
    GoRoute(path: '/login', builder: (context, state) => const Login()),
    GoRoute(path: '/register', builder: (context, state) => const Register()),
    GoRoute(
      path: '/workspace/:startupid',
      builder: (context, state) {
        final startupId = int.tryParse(state.pathParameters['startupid'] ?? '') ?? 0;
        return Workspace(startupId: startupId);
      },
    ),
    GoRoute(path: '/my-startups', builder: (context, state) => const MyStartups()),
    GoRoute(path: '/feedback', builder: (context, state) => const FeedbackPage()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(path: '/help-support', builder: (context, state) => const HelpSupportPage()),
  ],
  redirect: (context, state) {
    final loggedIn = _auth.currentUser != null;

    final isAuthPage =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!loggedIn && !isAuthPage) {
      return '/login';
    }

    if (loggedIn && isAuthPage) {
      return '/';
    }

    return null;
  },
);
