import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ValueNotifier<int> authNotifier = ValueNotifier<int>(0);

  AuthService() {
    _supabase.auth.onAuthStateChange.listen((_) {
      authNotifier.value++;
    });
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  void showAuthPopup(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final color = isError ? Colors.red : Colors.green;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Text(isError ? 'Error' : 'Success'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Sign in with email and password
  Future<AuthResponse?> signInWithEmailPassword(
    String email,
    String password, {
    BuildContext? context,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (context != null && context.mounted) {
        showAuthPopup(context, message: 'Login successful.', isError: false);
      }

      return response;
    } on AuthException catch (e) {
      if (context != null && context.mounted) {
        showAuthPopup(context, message: e.message, isError: true);
      }
      return null;
    } catch (e) {
      if (context != null && context.mounted) {
        showAuthPopup(context, message: e.toString(), isError: true);
      }
      return null;
    }
  }

  // Sign up with email and password
  Future<AuthResponse?> signUpWithEmailPassword(
    String email,
    String password, {
    BuildContext? context,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (context != null && context.mounted) {
        showAuthPopup(
          context,
          message: 'Account created successfully.',
          isError: false,
        );
      }

      return response;
    } on AuthException catch (e) {
      if (context != null && context.mounted) {
        showAuthPopup(context, message: e.message, isError: true);
      }
      return null;
    } catch (e) {
      if (context != null && context.mounted) {
        showAuthPopup(context, message: e.toString(), isError: true);
      }
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<bool> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,

        redirectTo: kIsWeb ? 'http://localhost:3000' : null,

        authScreenLaunchMode: LaunchMode.platformDefault,
      );

      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return false;
    }
  }
}
