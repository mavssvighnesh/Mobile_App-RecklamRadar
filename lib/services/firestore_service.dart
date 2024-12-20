import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/user_fields.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Profile Methods
  Future<void> createUserProfile(String userId, Map<String, dynamic> data) async {
    final isAdmin = data[UserFields.isBusiness] ?? false;
    final collection = isAdmin ? 'admins' : 'users';
    await _firestore.collection(collection).doc(userId).set(data);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      var doc = await _firestore.collection('admins').doc(userId).get();
      if (doc.exists) {
        return {
          'isAdmin': true,
          UserFields.name: doc.data()?[UserFields.name],
          UserFields.email: doc.data()?[UserFields.email],
          UserFields.phone: doc.data()?[UserFields.phone],
          UserFields.age: doc.data()?[UserFields.age],
          UserFields.gender: doc.data()?[UserFields.gender],
          UserFields.profileImage: doc.data()?[UserFields.profileImage],
        };
      }

      doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return {
          'isAdmin': false,
          UserFields.name: doc.data()?[UserFields.name],
          UserFields.email: doc.data()?[UserFields.email],
          UserFields.phone: doc.data()?[UserFields.phone],
          UserFields.age: doc.data()?[UserFields.age],
          UserFields.gender: doc.data()?[UserFields.gender],
          UserFields.profileImage: doc.data()?[UserFields.profileImage],
        };
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data, bool isAdmin) async {
    final collection = isAdmin ? 'admins' : 'users';
    await _firestore.collection(collection).doc(userId).update(data);
  }

  // Advertisement Methods
  Future<void> createAdvertisement(Map<String, dynamic> data) async {
    await _firestore.collection('advertisements').add({
      ...data,
      'userId': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAdvertisements() {
    return _firestore
        .collection('advertisements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserAdvertisements(String userId) {
    return _firestore
        .collection('advertisements')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Business Profile Methods
  Future<void> createBusinessProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('businesses').doc(userId).set(data);
  }

  Future<Map<String, dynamic>?> getBusinessProfile(String userId) async {
    final doc = await _firestore.collection('businesses').doc(userId).get();
    return doc.data();
  }

  // Categories
  Future<List<String>> getCategories() async {
    final doc = await _firestore.collection('metadata').doc('categories').get();
    return List<String>.from(doc.data()?['list'] ?? []);
  }

  // Favorites/Bookmarks
  Future<void> toggleFavorite(String adId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(adId);
    
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot> getFavorites() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots();
  }

  // Reviews and Ratings
  Future<void> addReview(String businessId, Map<String, dynamic> reviewData) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .add({
      ...reviewData,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getBusinessReviews(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
} 