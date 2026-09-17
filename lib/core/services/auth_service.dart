// lib/core/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Handles all Supabase Auth operations.
/// Errors are thrown as [AuthException] or [Exception] —
/// callers are responsible for try/catch.
class AuthService {
  AuthService._();

  static final _auth = SupabaseService.client.auth;

  // ---------------------------------------------------------------------------
  // Sign In
  // ---------------------------------------------------------------------------

  /// Sign in with email and password.
  /// Throws [AuthException] on invalid credentials or unconfirmed email.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ---------------------------------------------------------------------------
  // Sign Up
  // ---------------------------------------------------------------------------

  /// Register a new account with email and password.
  /// Supabase will send a confirmation email if email confirmation is enabled.
  /// Throws [AuthException] if the email is already registered.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _auth.signUp(
      email: email.trim(),
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  /// Sign out the current user and clear the local session.
  /// Throws [AuthException] on failure.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Password Reset
  // ---------------------------------------------------------------------------

  /// Send a password reset email to the given address.
  /// The deep link in the email should route to your reset password screen.
  /// Throws [AuthException] if the email is not found or rate limited.
  static Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    await _auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  /// Update the password for the currently authenticated user.
  /// Call this after the user arrives via the reset email deep link.
  /// Throws [AuthException] if the session is invalid or password is too weak.
  static Future<UserResponse> updatePassword({
    required String newPassword,
  }) async {
    return await _auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ---------------------------------------------------------------------------
  // Email Change
  // ---------------------------------------------------------------------------

  /// Initiate an email address change for the current user.
  /// Supabase sends a confirmation to the NEW email address.
  /// The change is not applied until the user confirms via that email.
  /// Throws [AuthException] if not authenticated or email already in use.
  static Future<UserResponse> updateEmail({
    required String newEmail,
  }) async {
    return await _auth.updateUser(
      UserAttributes(email: newEmail.trim()),
    );
  }

  // ---------------------------------------------------------------------------
  // Session / State Helpers
  // ---------------------------------------------------------------------------

  /// Returns the current session, or null if not signed in.
  static Session? get currentSession => _auth.currentSession;

  /// Returns the current user, or null if not signed in.
  static User? get currentUser => _auth.currentUser;

  /// True if a valid session exists.
  static bool get isSignedIn => _auth.currentUser != null;

  /// Stream of auth state changes.
  /// Useful for a top-level Riverpod StreamProvider to react to
  /// sign-in / sign-out / token refresh events.
  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}
