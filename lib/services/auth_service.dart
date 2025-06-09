import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _databaseService = DatabaseService();
  
  // Admin email constant
  static const String _adminEmail = "rhythmbharatarasadhana@gmail.com";

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if current user is admin
  bool isCurrentUserAdmin() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    return currentUser.email?.toLowerCase() == _adminEmail.toLowerCase();
  }

  // Get current admin user
  User? getCurrentAdminUser() {
    final currentUser = _auth.currentUser;
    if (currentUser?.email?.toLowerCase() == _adminEmail.toLowerCase()) {
      return currentUser;
    }
    return null;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // If this is the admin user, ensure they have proper admin privileges
      if (email.toLowerCase() == _adminEmail.toLowerCase()) {
        await _ensureAdminPrivileges(userCredential.user!);
      }

      return userCredential;
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
      Map<String, dynamic> userInfo = {
        "email": email,
        "name": name,
        "id": userCredential.user!.uid, // Using 'id' consistently
        "createdAt": FieldValue.serverTimestamp(),
      };

      // If this is the admin email, add admin privileges
      if (email.toLowerCase() == _adminEmail.toLowerCase()) {
        userInfo["isAdmin"] = true;
        userInfo["adminLevel"] = "primary";
        userInfo["adminSince"] = FieldValue.serverTimestamp();
      }

      await _databaseService.addUser(userCredential.user!.uid, userInfo);

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

      // If this is the admin user, ensure they have proper admin privileges
      if (user.email?.toLowerCase() == _adminEmail.toLowerCase()) {
        await _ensureAdminPrivileges(user);
      }

      return user;
    } catch (e) {
      debugPrint('Google sign in error: ${e.toString()}');
      return null;
    }
  }

  // Ensure admin user has proper privileges
  Future<void> _ensureAdminPrivileges(User user) async {
    try {
      if (user.email?.toLowerCase() != _adminEmail.toLowerCase()) {
        return; // Not admin user
      }

      // Check if user document exists and has admin privileges
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic> adminUpdateData = {
        "isAdmin": true,
        "adminLevel": "primary",
        "email": user.email,
        "lastAdminLogin": FieldValue.serverTimestamp(),
      };

      if (!userDoc.exists) {
        // Create admin document
        adminUpdateData["name"] = user.displayName ?? "Admin";
        adminUpdateData["id"] = user.uid;
        adminUpdateData["adminSince"] = FieldValue.serverTimestamp();
        adminUpdateData["createdAt"] = FieldValue.serverTimestamp();
        
        await _databaseService.addUser(user.uid, adminUpdateData);
      } else {
        // Update existing document with admin privileges
        final userData = userDoc.data() as Map<String, dynamic>?;
        
        if (userData?['isAdmin'] != true) {
          adminUpdateData["adminSince"] = FieldValue.serverTimestamp();
        }
        
        await _databaseService.updateUser(user.uid, adminUpdateData);
      }

      debugPrint('Admin privileges ensured for ${user.email}');
    } catch (e) {
      debugPrint('Error ensuring admin privileges: $e');
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

        // Check if this is admin user and add admin privileges if missing
        if (user.email?.toLowerCase() == _adminEmail.toLowerCase()) {
          if (userData?['isAdmin'] != true) {
            updateData["isAdmin"] = true;
            updateData["adminLevel"] = "primary";
            updateData["adminSince"] = FieldValue.serverTimestamp();
          }
          updateData["lastAdminLogin"] = FieldValue.serverTimestamp();
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

        // Check if this is admin user
        if (user.email?.toLowerCase() == _adminEmail.toLowerCase()) {
          userInfoMap["isAdmin"] = true;
          userInfoMap["adminLevel"] = "primary";
          userInfoMap["adminSince"] = FieldValue.serverTimestamp();
          userInfoMap["lastAdminLogin"] = FieldValue.serverTimestamp();
        }

        await _databaseService.addUser(user.uid, userInfoMap);
      }
    } catch (e) {
      // Log error but don't throw - authentication still succeeded
      debugPrint('Error storing user data: ${e.toString()}');
    }
  }

  // Get admin user info
  Future<Map<String, dynamic>?> getAdminUserInfo() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser?.email?.toLowerCase() != _adminEmail.toLowerCase()) {
        return null;
      }

      return await _databaseService.getUserById(currentUser!.uid);
    } catch (e) {
      debugPrint('Error getting admin user info: $e');
      return null;
    }
  }

  // Check if user exists in system
  Future<bool> userExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Admin function: Create user account
  Future<UserCredential?> createUserAccount(
    String name,
    String email,
    String password,
  ) async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Admin privileges required');
      }

      // Create the user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Store user data
      await _databaseService.addUser(userCredential.user!.uid, {
        "email": email,
        "name": name,
        "id": userCredential.user!.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "createdByAdmin": true,
        "createdBy": _auth.currentUser?.email,
      });

      return userCredential;
    } catch (e) {
      debugPrint('Error creating user account: $e');
      rethrow;
    }
  }

  // Admin function: Reset any user's password
  Future<void> resetUserPassword(String email) async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Admin privileges required');
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('Error resetting user password: $e');
      rethrow;
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