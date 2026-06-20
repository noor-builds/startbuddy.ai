import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class HttpService {
  static String get baseUrl {
    // In debug mode, prefer local server; in release, use production
    
    return const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'https://startbuddybackend.vercel.app',
    );
  }

  Future<http.Response> validate(String prompt) async {
    final body = <String, dynamic>{
      'prompt': prompt,
    };
    
    // Only add authId if it's not null
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      body['authId'] = userId;
    }
    
    return http.post(
      Uri.parse('$baseUrl/ai/validate-idea'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> generateBlueprint(int startupId) async {
    final body = <String, dynamic>{
      'startupId': startupId,
    };
    
    // Only add authId if it's not null
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      body['authId'] = userId;
    }
    
    return http.post(
      Uri.parse('$baseUrl/ai/generate-blueprint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> generateRoadmap(int startupId, String stage) async {
    final body = <String, dynamic>{
      'startupId': startupId,
      'stage': stage,
    };
    
    // Only add authId if it's not null
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      body['authId'] = userId;
    }
    
    return http.post(
      Uri.parse('$baseUrl/ai/generate-roadmap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> chat({
    required int startupId,
    required String? chatId,
    required String message,
  }) async {
    final body = <String, dynamic>{
      'startupId': startupId,
      'message': message,
    };
    
    // Only add authId if it's not null
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      body['authId'] = userId;
    }
    
    // Only add chatId if it's not null
    if (chatId != null) {
      body['chatId'] = chatId;
    }
    
    return http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> generateDocument(int startupId, String type) async {
    final body = <String, dynamic>{
      'startupId': startupId,
      'type': type,
    };
    
    // Only add authId if it's not null
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      body['authId'] = userId;
    }
    
    return http.post(
      Uri.parse('$baseUrl/ai/generate-document'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }
}