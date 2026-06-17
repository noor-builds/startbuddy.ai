import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class HttpService {
  static String get baseUrl {
    // For Vercel production deployment:
    // return 'https://startbuddybackend.vercel.app';

    // For local development, point to the express server running on port 3000/3001
    // In Flutter, 'localhost' works for web/desktop, but Android emulator requires 10.0.2.2.
    // We can auto-resolve it or use a default:
    return 'http://startbuddybackend.vercel.app'; // Change this to your local server URL if needed
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

  Future<http.Response> generateBlueprint(int startupId) async {
    return http.post(
      Uri.parse('$baseUrl/ai/generate-blueprint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'authId': Supabase.instance.client.auth.currentUser?.id,
        'startupId': startupId,
      }),
    );
  }

  Future<http.Response> generateRoadmap(int startupId, String stage) async {
    return http.post(
      Uri.parse('$baseUrl/ai/generate-roadmap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'authId': Supabase.instance.client.auth.currentUser?.id,
        'startupId': startupId,
        'stage': stage,
      }),
    );
  }

  Future<http.Response> chat({
    required int startupId,
    required String? chatId,
    required String message,
  }) async {
    return http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'authId': Supabase.instance.client.auth.currentUser?.id,
        'startupId': startupId,
        'chatId': chatId,
        'message': message,
      }),
    );
  }

  Future<http.Response> generateDocument(int startupId, String type) async {
    return http.post(
      Uri.parse('$baseUrl/ai/generate-document'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'authId': Supabase.instance.client.auth.currentUser?.id,
        'startupId': startupId,
        'type': type,
      }),
    );
  }
}
