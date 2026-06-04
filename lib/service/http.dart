import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class HttpService {
  static const _configuredBaseUrl = String.fromEnvironment(
    'STARTBUDDY_API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'https://startbuddybackend.vercel.app';
      }
      return 'https://startbuddybackend.vercel.app';
    }

    return 'https://startbuddybackend.vercel.app';
  }

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
}
