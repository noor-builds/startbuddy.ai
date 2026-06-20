import 'package:flutter/material.dart';
import 'package:startbuddy/router/router.dart';
import 'package:startbuddy/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ypqgdftexhiwocjvdorz.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_tXogFpvY7Vd4V_LxMrsyJQ_IgSVATA2',
  );

  await Supabase.initialize(
    anonKey: supabaseAnonKey,
    url: supabaseUrl,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      title: 'startbuddy.ai',
      debugShowCheckedModeBanner: false,
    );
  }
}
