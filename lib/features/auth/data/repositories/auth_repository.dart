import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_registrar.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  bool _googleSignInInitialized = false;

  static const String _keyIsGuest = 'is_guest_user';

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isGuest {
    if (_auth.currentUser != null) return false;
    try {
      final box = Hive.box(HiveRegistrar.settingsBoxName);
      return box.get(_keyIsGuest, defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  Future<void> setGuest(bool value) async {
    try {
      final box = Hive.box(HiveRegistrar.settingsBoxName);
      await box.put(_keyIsGuest, value);
    } catch (_) {}
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.initialize();
        _googleSignInInitialized = true;
      } catch (e) {
        developer.log('GoogleSignIn initialize warning: $e', name: 'AuthRepository');
      }
    }
  }

  /// Fetches the Firestore profile for the currently logged-in user.
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (isGuest) {
        return const UserModel(
          uid: 'guest_user',
          displayName: 'Guest Habitraker',
          isAnonymous: true,
        );
      }
      return null;
    }

    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc);
      } else {
        // If Firestore record doesn't exist yet, create one
        return await _createOrUpdateUserInFirestore(user);
      }
    } catch (e) {
      developer.log('Error fetching user profile: $e', name: 'AuthRepository');
      return UserModel.fromFirebaseUser(user);
    }
  }

  /// Sign in with Google and sync user data to Firestore
  Future<UserModel> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      final authz = await account.authorizationClient.authorizationForScopes(['email']);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'ERROR_USER_NULL',
          message: 'Failed to retrieve user after Google sign-in.',
        );
      }

      await setGuest(false);
      return await _createOrUpdateUserInFirestore(user);
    } catch (e) {
      developer.log('Error in signInWithGoogle: $e', name: 'AuthRepository');
      rethrow;
    }
  }

  /// Sign in as a Guest (Anonymous) and initialize Firestore document
  Future<UserModel> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'ERROR_USER_NULL',
          message: 'Failed to sign in anonymously.',
        );
      }

      await setGuest(true);
      try {
        return await _createOrUpdateUserInFirestore(user);
      } catch (firestoreError) {
        developer.log('Firestore profile create warning in guest mode: $firestoreError', name: 'AuthRepository');
        return UserModel.fromFirebaseUser(user);
      }
    } catch (e) {
      developer.log('Error in signInAnonymously: $e', name: 'AuthRepository');
      // If Firebase anonymous auth encounters an error, fallback to local guest session
      await setGuest(true);
      return const UserModel(
        uid: 'guest_user',
        displayName: 'Guest Habitraker',
        isAnonymous: true,
      );
    }
  }

  /// Saves or updates the user profile record in the Firestore 'users' collection.
  Future<UserModel> _createOrUpdateUserInFirestore(User user) async {
    final userDocRef = _usersCollection.doc(user.uid);
    final snapshot = await userDocRef.get();

    if (!snapshot.exists) {
      // First-time registration: Create complete initial profile
      final newUser = UserModel.fromFirebaseUser(user);
      final initialData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? (user.isAnonymous ? 'Guest Habitraker' : 'Mindful Explorer'),
        'photoUrl': user.photoURL,
        'isAnonymous': user.isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'accountStatus': 'active',
        'preferences': {
          'themeMode': 'dark',
          'remindersEnabled': true,
          'dailyReminderTime': '08:00',
        },
        'stats': {
          'currentStreak': 0,
          'longestStreak': 0,
          'totalCompletedHabits': 0,
          'mindfulMinutes': 0,
        },
      };

      await userDocRef.set(initialData, SetOptions(merge: true));
      return newUser;
    } else {
      // Existing user: Update last login and refresh profile info
      final updateData = <String, dynamic>{
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (user.email != null && user.email!.isNotEmpty) {
        updateData['email'] = user.email;
      }
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        updateData['displayName'] = user.displayName;
      }
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        updateData['photoUrl'] = user.photoURL;
      }

      await userDocRef.update(updateData);
      final updatedSnap = await userDocRef.get();
      return UserModel.fromFirestore(updatedSnap);
    }
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    await setGuest(false);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Safe to ignore if not signed in to Google
    }
    await _auth.signOut();
  }
}
