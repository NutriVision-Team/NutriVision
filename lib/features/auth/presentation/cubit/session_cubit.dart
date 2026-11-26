import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/user_profile_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../services/auth_service.dart';

/// Session-level authentication state used by the router redirect.
sealed class SessionState {
  const SessionState();
}

/// Auth state not yet resolved (splash).
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

class SessionAuthenticated extends SessionState {
  const SessionAuthenticated({required this.user, this.profile});

  final User user;

  /// Null while the profile document is still loading.
  final UserProfileModel? profile;

  /// True when the account exists but the personal setup was never finished.
  bool get needsSetup => profile == null || !profile!.onboardingCompleted;

  bool get isReady => profile != null && profile!.onboardingCompleted;
}

class SessionFailure extends SessionState {
  const SessionFailure(this.message);

  final String message;
}

/// Tracks Firebase auth state and the user's Firestore profile so the
/// router can send every state to the right destination.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required AuthService authService,
    required UserRepository userRepository,
    this.beforeSignOut,
    this.afterSignOut,
  }) : _authService = authService,
       _userRepository = userRepository,
       super(const SessionUnknown()) {
    _subscription = _authService.authStateChanges.listen(_onAuthChanged);
  }

  final Future<void> Function()? beforeSignOut;
  final void Function()? afterSignOut;
  final AuthService _authService;
  final UserRepository _userRepository;
  late final StreamSubscription<User?> _subscription;
  int _generation = 0;
  bool _authOperation = false;

  /// Keep routing stable until linking/profile creation finishes.
  Future<T> completeAuthOperation<T>(Future<T> Function() operation) async {
    if (_authOperation) throw StateError('Authentication already in progress');
    _authOperation = true;
    _generation++;
    try {
      return await operation();
    } finally {
      _authOperation = false;
      await _onAuthChanged(_authService.currentUser);
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    if (_authOperation) return;
    final generation = ++_generation;
    if (isClosed) return;
    if (user == null) {
      emit(const SessionUnauthenticated());
      return;
    }
    // Do not retain the previous account's profile while this read resolves.
    emit(const SessionUnknown());
    try {
      final profile = await _userRepository.getCurrentUser();
      if (isClosed || generation != _generation) return;
      if (profile != null && profile.uid != user.uid) {
        emit(const SessionFailure('Profile account mismatch'));
        return;
      }
      emit(SessionAuthenticated(user: user, profile: profile));
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(const SessionFailure('Profile unavailable'));
      }
    }
  }

  /// Re-read the profile (e.g. after registration or setup completion).
  Future<void> refreshProfile() async {
    final current = state;
    if (current is! SessionAuthenticated) return;
    try {
      final generation = _generation;
      final profile = await _userRepository.getCurrentUser();
      if (isClosed ||
          generation != _generation ||
          (profile != null && profile.uid != current.user.uid)) {
        return;
      }
      emit(SessionAuthenticated(user: current.user, profile: profile));
    } catch (_) {
      // Keep previous state on transient failures.
    }
  }

  Future<void> signOut() async {
    try {
      await beforeSignOut?.call();
      await _authService.signOut();
    } finally {
      afterSignOut?.call();
    }
  }

  @override
  Future<void> close() {
    _generation++;
    _subscription.cancel();
    return super.close();
  }
}
