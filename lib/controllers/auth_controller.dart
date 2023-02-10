import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoplist/repositories/auth_repository.dart';

final authControllerProvider = StateNotifierProvider<AuthController, User?>(
  // As soon as the app loads users will be authenticated
  (ref) => AuthController(ref)..appStarted(),
);

class AuthController extends StateNotifier<User?> {
  final Ref _ref;

  StreamSubscription<User?>? _authStateChangesSubscription;

  // Set initial state of AuthController to null because no user is signed in.
  AuthController(this._ref) : super(null) {
    // Update auth controller state whenever a user logs in or logs out.
    _authStateChangesSubscription?.cancel();
    _authStateChangesSubscription = _ref
        .read(authRepositoryProvider)
        .authStateChanges
        .listen((user) => state = user);
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    super.dispose();
  }

  void appStarted() async {
    final user = _ref.read(authRepositoryProvider).getCurrentUser();
    if (user == null) {
      await _ref.read(authRepositoryProvider).signInAnonymously();
    }
  }

  void signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
  }
}
