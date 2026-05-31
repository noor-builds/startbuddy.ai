import 'package:go_router/go_router.dart';
import 'package:startbuddy/page/home.dart';
import 'package:startbuddy/page/loading.dart';
import 'package:startbuddy/page/login.dart';
import 'package:startbuddy/page/register.dart';
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
  ],
  redirect: (context, state) {
    final loggedIn = _auth.currentUser != null;

    final isAuthPage = state.matchedLocation == '/login' ||
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
