import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _databaseService = DatabaseService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // FIXED: Store additional user info in database with consistent 'id' field
      await _databaseService.addUser(userCredential.user!.uid, {
        "email": email,
        "name": name,
        "id": userCredential.user!.uid, // Using 'id' consistently
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Sign out first to force account selection dialog
      await _googleSignIn.signOut();

      // Start the Google sign-in process
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      if (googleSignInAccount == null) {
        // User canceled the sign-in
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      // Create credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Get user details
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to get user details after Google sign in');
      }

      // Get the Google profile photo URL
      final String? photoURL = googleSignInAccount.photoUrl;

      // Store user information in Firestore
      await _storeUserData(user, googlePhotoURL: photoURL);

      return user;
    } catch (e) {
      debugPrint('Google sign in error: ${e.toString()}');
      return null;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: ${e.toString()}');
    }
  }

  // FIXED: Store user data in Firestore with consistent 'id' field usage
  Future<void> _storeUserData(User user, {String? googlePhotoURL}) async {
    try {
      // Check if user document already exists
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;

        // Only update fields that should be updated on login
        final Map<String, dynamic> updateData = {
          "email": user.email,
          "lastLogin": FieldValue.serverTimestamp(),
        };

        // If user doesn't have an image URL set already, use Google's
        if ((userData?['imgUrl'] == null || userData!['imgUrl'].isEmpty) &&
            (userData?['imgBase64'] == null ||
                userData!['imgBase64'].isEmpty) &&
            (googlePhotoURL != null && googlePhotoURL.isNotEmpty)) {
          updateData["imgUrl"] = googlePhotoURL;
        }

        // If user name is null or empty, update it
        if (userData?['name'] == null || userData!['name'].isEmpty) {
          updateData["name"] =
              user.displayName ?? user.email?.split('@')[0] ?? 'User';
        }

        await _databaseService.updateUser(user.uid, updateData);
      } else {
        // FIXED: For new users, create a complete profile with consistent 'id' field
        final Map<String, dynamic> userInfoMap = {
          "email": user.email,
          "name": user.displayName ?? user.email?.split('@')[0] ?? 'User',
          "imgUrl": googlePhotoURL ?? user.photoURL ?? "",
          "id": user.uid, // Using 'id' consistently instead of mixing uid/id
          "lastLogin": FieldValue.serverTimestamp(),
          "createdAt": FieldValue.serverTimestamp(),
        };

        await _databaseService.addUser(user.uid, userInfoMap);
      }
    } catch (e) {
      // Log error but don't throw - authentication still succeeded
      debugPrint('Error storing user data: ${e.toString()}');
    }
  }

  // Handle Firebase Auth exceptions with user-friendly messages
  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'invalid-email':
        message = 'Please provide a valid email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please use a stronger password.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message =
            'Too many unsuccessful login attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        message = 'This sign-in method is not enabled.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      case 'invalid-credential':
        message = 'Invalid login credentials. Please check your email and password.';
        break;
      default:
        message = e.message ?? 'Authentication failed. Please try again.';
    }

    return Exception(message);
  }
}