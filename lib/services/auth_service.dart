import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recklamradar/constants/user_fields.dart';
import 'dart:io';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Add stream to track auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Sign Up
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String name,
    bool isBusiness,
    String? imageUrl,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update user profile with photo URL
        await credential.user!.updatePhotoURL(imageUrl);
        
        // Create user profile in appropriate collection
        await _firestoreService.createUserProfile(
          credential.user!.uid,
          {
            UserFields.name: name,
            UserFields.email: email,
            UserFields.isBusiness: isBusiness,
            UserFields.profileImage: imageUrl,
            UserFields.createdAt: FieldValue.serverTimestamp(),
          },
        );
      }

      return credential;
    } catch (e) {
      print('Sign-up error: ${e.toString()}');
      rethrow; // Rethrow to handle in UI
    }
  }

  // Upload Profile Image
  Future<String?> uploadProfileImage(String userId, File profileImage) async {
    try {
      final ref = _storage.ref().child('user_profiles').child('$userId.jpg');
      final uploadTask = await ref.putFile(profileImage);

      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw 'Failed to upload profile image: ${uploadTask.state}';
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Email & Password Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Determine user role
        final isBusiness = email.toLowerCase().endsWith('@rr.com');

        // Update last login information in the appropriate collection
        await _firestore
            .collection(isBusiness ? 'admins' : 'users')
            .doc(credential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } catch (e) {
      print('Sign-in error: ${e.toString()}');
      return null;
    }
  }

  // Facebook Sign In
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return null;

      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken?.token ?? '',
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Store Facebook sign-in users as regular users
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'isBusiness': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return userCredential;
    } catch (e) {
      print('Facebook sign-in error: ${e.toString()}');
      return null;
    }
  }

  // Fetch User Data by Role
  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    try {
      // Check if user exists in the admins collection
      final adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        return {'isAdmin': true, ...adminDoc.data()!};
      }

      // Check if user exists in the users collection
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return {'isAdmin': false, ...userDoc.data()!};
      }

      return null; // User not found
    } catch (e) {
      print('Fetch user data error: ${e.toString()}');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Successfully signed out');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      // Determine collection based on user's business status
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final isBusiness = (userDoc.exists && userDoc.data()?[UserFields.isBusiness] == true);
      final collection = isBusiness ? 'admins' : 'users';

      await _firestore.collection(collection).doc(userId).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
