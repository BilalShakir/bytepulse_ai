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
    String displayName = 'Test Developer',
    String email = 'dev@bytepulse.ai',
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

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!_initialized) {
        await initializeFirebase();
      }
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        _demoUser = null;
        _authController.add(userCredential.user);
      }
      return userCredential;
    } catch (e) {
      debugPrint("Google Sign-In caught safely: $e");
      return null;
    }
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
