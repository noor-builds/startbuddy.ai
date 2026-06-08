import 'dart:convert';


import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class HttpService {
  static String get baseUrl {
    
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
