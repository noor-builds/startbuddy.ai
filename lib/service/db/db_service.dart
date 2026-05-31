import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<  void> createUser({
    required String name,
    required String email,
    required int age,
  }) async {
    final user = _supabase.auth.currentUser;

    try {
      await _supabase.from('users').insert({
        'auth_id': user!.id,
        'name': name.trim(),
        'email': email.trim(),
        'age': age,
      });
    } on PostgrestException catch (e) {
     throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> saveStartupIdea({
    required String startupName,
    required String startupDescription,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'You must be signed in to save your startup idea.',
      );
    }

    return _supabase
        .from('users')
        .upsert({
          'auth_id': user.id,
          'startup_name': startupName.trim(),
          'startup_description': startupDescription.trim(),
        }, onConflict: 'auth_id')
        .select()
        .single();
  }




  Future<List<Map<String, dynamic>>> fetchUserStartups() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const AuthException('You must be signed in to view your startups.');
    }

    final response = await _supabase
        .from('startup')
        .select('id, created_at, "startup name", description, validation_report')
        .eq('authid', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String?> fetchLatestStartupName() async {
    final startups = await fetchUserStartups();
    if (startups.isEmpty) return null;
    return startups.first['startup name'] as String?;
  }

  @Deprecated('Use fetchLatestStartupName or fetchUserStartups')
  Future fetchUserStartupName() async {
    return fetchLatestStartupName();
  }
}
