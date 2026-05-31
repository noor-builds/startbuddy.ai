import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class HttpService {
  static const productionBaseUrl = 'https://startbuddybackend.vercel.app';

  /// Flutter web debug: run `npm run dev` in `server/` (uses port from .env).
  static const localBaseUrl = 'http://localhost:3001';

  static String get baseUrl =>
      kIsWeb && kDebugMode ? localBaseUrl : productionBaseUrl;

  Future<http.Response> validate(String prompt) async {
    return http.post(
      Uri.parse('$baseUrl/ai/validate-idea'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'authid': Supabase.instance.client.auth.currentUser?.id,
        'prompt': prompt,
      }),
    );
  }

  /// Quick check that the browser can reach the API (CORS + network).
  Future<bool> canReachApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
