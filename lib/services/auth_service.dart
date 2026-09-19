// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/errors/app_exception.dart';
import '../models/user_profile.dart';
import 'user_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Returns the current user if already signed in.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in with Google, linking to any existing anonymous account.
  /// Returns the Firebase user. Creates Firestore profile if new.
  Future<User> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthException('Google sign-in cancelled.');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? user;
      final currentAnon = _auth.currentUser;

      if (currentAnon != null && currentAnon.isAnonymous) {
        // Try to link Google to the existing anonymous account
        try {
          final result = await currentAnon.linkWithCredential(credential);
          user = result.user;
          print('[AUTH] Google linked to anonymous UID: ${user?.uid}');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
            // The Google account already has a Firebase UID — sign in to it instead
            print('[AUTH] Google credential already exists, signing in directly');
            final result = await _auth.signInWithCredential(credential);
            user = result.user;
          } else {
            rethrow;
          }
        }
      } else {
        // No anonymous account — direct Google sign-in
        final result = await _auth.signInWithCredential(credential);
        user = result.user;
        print('[AUTH] Google sign-in: ${user?.uid}');
      }

      if (user == null) throw const AuthException('Google sign-in returned no user.');

      // Ensure Firestore profile exists
      final userService = UserService();
      final existing = await userService.getProfile(user.uid);
      if (existing == null) {
        final username = _sanitizeUsername(googleUser.displayName ?? user.uid.substring(0, 8));
        final profile = UserProfile(
          uid: user.uid,
          displayName: googleUser.displayName ?? 'Player',
          username: username,
          usernameLowercase: username.toLowerCase(),
          avatarUrl: googleUser.photoUrl,
          status: UserStatus.online,
          createdAt: DateTime.now(),
        );
        await userService.createProfile(profile);
        print('[AUTH] Firestore profile created for ${user.uid}');
      } else {
        // Update status to online
        await userService.updateStatus(user.uid, UserStatus.online);
      }

      return user;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException('Google sign-in failed: ${e.message ?? e.code}');
    } catch (e) {
      throw AuthException('Unexpected auth error: $e');
    }
  }

  /// Silent sign-in on app restart (reuses existing Google session).
  Future<User?> signInSilently() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && !currentUser.isAnonymous) return currentUser;

      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        final userService = UserService();
        await userService.updateStatus(user.uid, UserStatus.online);
      }
      return user;
    } catch (e) {
      print('[AUTH] Silent sign-in failed: $e');
      return null;
    }
  }

  /// Signs out completely.
  Future<void> signOut() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await UserService().updateStatus(uid, UserStatus.offline);
      }
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Sign-out failed: $e');
    }
  }

  /// Gets a fresh Firebase ID token for the token server.
  Future<String> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated.');
    final token = await user.getIdToken();
    return token ?? (throw const AuthException('Could not get ID token.'));
  }

  /// Returns the current Firebase UID. Throws if not authenticated.
  String get uid {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated.');
    return user.uid;
  }

  String _sanitizeUsername(String raw) {
    // Keep alphanumeric and underscores, lowercase, max 20 chars
    final cleaned = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return cleaned.isEmpty ? 'player' : cleaned.substring(0, cleaned.length.clamp(0, 20));
  }
}
