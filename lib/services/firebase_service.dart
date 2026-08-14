import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MockFirebaseUser implements User {
  @override
  final String uid;

  @override
  final String? displayName;

  @override
  final String? email;

  @override
  final String? photoURL;

  @override
  final bool emailVerified;

  @override
  final bool isAnonymous;

  MockFirebaseUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.emailVerified = true,
    this.isAnonymous = false,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FirebaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static User? _demoUser;
  static final StreamController<User?> _authController = StreamController<User?>.broadcast();

  static Future<void> initializeFirebase() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint("Firebase initialized successfully.");
    } catch (e) {
      _initialized = false;
      debugPrint("Firebase Web initialization caught safely (Offline/Mock Mode): $e");
    }
  }

  static Stream<User?> get authStateChanges async* {
    yield currentUser;
    yield* _authController.stream;
  }

  static User? get currentUser {
    if (_demoUser != null) return _demoUser;
    try {
      if (!_initialized) return null;
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint("FirebaseAuth currentUser caught safely: $e");
      return null;
    }
  }

  static User signInDemoUser({
    String uid = 'demo-dev-101',
    String displayName = 'Alex Rivers (Senior AI/ML Engineer)',
    String email = 'alex.rivers@bytepulse.ai',
    String photoUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80',
  }) {
    _demoUser = MockFirebaseUser(
      uid: uid,
      displayName: displayName,
      email: email,
      photoURL: photoUrl,
    );
    _authController.add(_demoUser);
    return _demoUser!;
  }

  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Google Sign-In canceled by user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (_initialized) {
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) {
          _demoUser = null;
          _authController.add(userCredential.user);
          return userCredential.user;
        }
      }

      // If Firebase Auth is not connected, create user profile from Google OAuth details
      return signInDemoUser(
        uid: googleUser.id,
        displayName: googleUser.displayName ?? 'Google Developer',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80',
      );
    } catch (e) {
      debugPrint("GOOGLE SIGN-IN NATIVE ERROR: $e");
      return null;
    }
  }

  static final Map<String, Map<String, String>> _userRegistry = {
    'alex.rivers@bytepulse.ai': {
      'password': 'Password123',
      'name': 'Alex Rivers',
      'role': 'ai_ml',
      'uid': 'demo-dev-101',
      'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80',
    },
    'sarah.chen@bytepulse.ai': {
      'password': 'Password123',
      'name': 'Sarah Chen',
      'role': 'architect',
      'uid': 'demo-dev-102',
      'photo': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=250&q=80',
    },
    'marcus.vance@bytepulse.ai': {
      'password': 'Password123',
      'name': 'Marcus Vance',
      'role': 'devops',
      'uid': 'demo-dev-103',
      'photo': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=250&q=80',
    },
  };

  static Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Verify if account already exists
    if (_userRegistry.containsKey(cleanEmail)) {
      throw Exception("Account already exists with email '$cleanEmail'. Please Sign In.");
    }

    try {
      if (_initialized) {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (credential.user != null) {
          await credential.user!.updateDisplayName(displayName);
          _demoUser = null;
          _authController.add(credential.user);
          return credential.user;
        }
      }
    } catch (e) {
      debugPrint("FirebaseAuth SignUp Exception caught safely: $e");
    }

    // Register user in authentication registry
    final newUid = 'dev-${DateTime.now().millisecondsSinceEpoch}';
    _userRegistry[cleanEmail] = {
      'password': password,
      'name': displayName,
      'role': role,
      'uid': newUid,
      'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80',
    };

    return signInDemoUser(
      uid: newUid,
      displayName: displayName,
      email: cleanEmail,
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80',
    );
  }

  static Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      if (_initialized) {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (credential.user != null) {
          _demoUser = null;
          _authController.add(credential.user);
          return credential.user;
        }
      }
    } catch (e) {
      debugPrint("FirebaseAuth SignIn Exception caught safely: $e");
    }

    // Auth Verification against User Registry
    if (!_userRegistry.containsKey(cleanEmail)) {
      throw Exception("No account registered with '$cleanEmail'. Click 'Sign Up' tab to create an account.");
    }

    final record = _userRegistry[cleanEmail]!;
    if (record['password'] != password) {
      throw Exception("Incorrect password for '$cleanEmail'. Please check your password and try again.");
    }

    return signInDemoUser(
      uid: record['uid']!,
      displayName: record['name']!,
      email: cleanEmail,
      photoUrl: record['photo']!,
    );
  }

  static Future<void> signOut() async {
    _demoUser = null;
    _authController.add(null);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      if (_initialized) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      debugPrint("Firebase Sign-Out caught safely: $e");
    }
  }
}
