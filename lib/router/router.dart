import 'package:go_router/go_router.dart';
import 'package:startbuddy/page/home.dart';
import 'package:startbuddy/page/login.dart';
import 'package:startbuddy/page/register.dart';
import 'package:startbuddy/service/auth/auth_servvice.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/login', builder: (context, state) => const Login()),
    GoRoute(path: '/register', builder: (context, state) => const Register()),
    
    
    ],


   redirect: (context, state) {
  final loggedIn = AuthService().currentUser != null;

  final isAuthPage =
      state.matchedLocation == '/login' ||
      state.matchedLocation == '/register';

  // User not logged in
  if (!loggedIn && !isAuthPage) {
    return '/login';
  }

  // User already logged in
  if (loggedIn && isAuthPage) {
    return '/home';
  }

  return null;
},
);
