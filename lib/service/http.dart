import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class HttpService {
  /// Override for local dev, e.g.
  /// `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3001`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://startbuddy-ai-x2ex.vercel.app',
  );

  static String get validateUrl => '$apiBaseUrl/ai/validate-idea';

  Future<http.Response> validate(String prompt) async {
    final authId = Supabase.instance.client.auth.currentUser?.id;
    developer.log(
      'POST $validateUrl (prompt: ${prompt.length} chars, auth: ${authId != null})',
      name: 'validator.ai',
    );

    try {
      final response = await http.post(
        Uri.parse(validateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'authid': authId, 'prompt': prompt}),
      );

      developer.log(
        'Response ${response.statusCode} (${response.body.length} bytes)',
        name: 'validator.ai',
      );
      return response;
    } on http.ClientException catch (e, st) {
      developer.log(
        'Network request failed',
        name: 'validator.ai',
        error: e,
        stackTrace: st,
      );
      throw HttpNetworkException(message: _networkErrorMessage(e), cause: e);
    }
  }

  String _networkErrorMessage(http.ClientException e) {
    if (kIsWeb) {
      return 'Could not reach the API (browser blocked the request). '
          'Redeploy the server with CORS enabled, or run the API locally and '
          'start Flutter with '
          '--dart-define=API_BASE_URL=http://localhost:3001';
    }
    return 'Could not reach the API: ${e.message}';
  }
}

class HttpNetworkException implements Exception {
  HttpNetworkException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
