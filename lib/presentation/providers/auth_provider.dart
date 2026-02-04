import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';

/// Result of a sign-up attempt
class SignUpResult {
  final bool needsEmailConfirmation;
  final String? error;

  SignUpResult({
    this.needsEmailConfirmation = false,
    this.error,
  });

  bool get isSuccess => error == null;
}

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Current auth state stream
final authStateProvider = StreamProvider<Session?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges.map((state) => state.session);
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUser;
});

/// Auth notifier for handling auth actions
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Sign up and return result indicating if email confirmation is needed
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      // If user exists but no session, email confirmation is required
      final needsConfirmation = response.user != null && response.session == null;

      state = const AsyncValue.data(null);
      return SignUpResult(needsEmailConfirmation: needsConfirmation);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return SignUpResult(error: e.toString());
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signIn(email: email, password: password);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signInWithGoogle();
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signInWithApple();
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signOut();
    });
  }

  Future<void> resetPassword({required String email}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.resetPassword(email: email);
    });
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
