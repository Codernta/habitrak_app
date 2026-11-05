import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _authRepository.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        final profile = await _authRepository.getCurrentUserProfile();
        if (profile != null) {
          emit(Authenticated(profile));
        } else {
          emit(Authenticated(UserModel.fromFirebaseUser(firebaseUser)));
        }
      } else {
        emit(const Unauthenticated());
      }
    });
  }

  Future<void> checkAuthStatus() async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(const AuthLoading(message: 'Restoring session...'));
      final profile = await _authRepository.getCurrentUserProfile();
      emit(Authenticated(profile ?? UserModel.fromFirebaseUser(user)));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> loginWithGoogle() async {
    emit(const AuthLoading(message: 'Signing in with Google...'));
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(Authenticated(user));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'ERROR_ABORTED_BY_USER' || e.code == 'popup_closed_by_user') {
        emit(const Unauthenticated());
      } else {
        emit(AuthError(e.message ?? 'Authentication failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> continueAsGuest() async {
    emit(const AuthLoading(message: 'Preparing your mindful space...'));
    try {
      final user = await _authRepository.signInAnonymously();
      emit(Authenticated(user));
    } catch (e) {
      // If Firebase anonymous authentication is not enabled in Firebase Console,
      // fallback smoothly to a local guest profile so users can always enter and use the app offline or without credentials.
      final guest = UserModel(
        uid: 'guest_local_user',
        email: 'guest@habitrak.local',
        displayName: 'Mindful Explorer',
        photoUrl: null,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isAnonymous: true,
      );
      emit(Authenticated(guest));
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading(message: 'Signing out...'));
    try {
      await _authRepository.signOut();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
