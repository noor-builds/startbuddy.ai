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
     return await _supabase.from('users').insert({
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




  Future fetchUserStartupName() async {
  final response = await Supabase.instance.client
      .from('users')
      .select('startup_name')
      .eq('auth_id',_supabase.auth.currentUser!.id)
      .maybeSingle();

  final startupName = response?['startup_name'] as String?;
  return startupName;
}
}
