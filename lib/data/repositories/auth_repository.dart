import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );

    if (response.user != null) {
      // Create profile record
      await _createProfile(response.user!.id, displayName);
    }

    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with magic link
  Future<void> signInWithMagicLink({required String email}) async {
    await _client.auth.signInWithOtp(email: email);
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _getRedirectUrl(),
    );
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: _getRedirectUrl(),
    );
  }

  /// Get the appropriate redirect URL based on platform
  String? _getRedirectUrl() {
    // For web, let Supabase use the current URL
    // For mobile, use deep link
    return null; // Supabase will use Site URL from dashboard
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Create user profile after signup
  Future<void> _createProfile(String userId, String? displayName) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'display_name': displayName,
      'notification_preferences': {'daily_digest': true, 'repurchase_reminders': true},
    });

    // Also create a default shopping list
    await _client.from('lists').insert({
      'user_id': userId,
      'name': 'Shopping List',
    });
  }
}
