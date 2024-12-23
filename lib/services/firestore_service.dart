import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recklamradar/models/deal.dart';
import 'package:recklamradar/models/store.dart';
import 'dart:io';
import '../constants/user_fields.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
  Future<void> toggleFavorite(String userId, String dealId) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(dealId);
    
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'addedAt': FieldValue.serverTimestamp(),
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

  // Store Methods
  Stream<List<Store>> getStores() {
    return _firestore
        .collection('stores')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Store.fromFirestore(doc))
            .toList());
  }

  Future<DocumentSnapshot> getStore(String storeId) {
    return _firestore.collection('stores').doc(storeId).get();
  }

  // Products/Deals Methods
  Stream<List<Deal>> getStoreDeals(String storeId) {
    return _firestore
        .collection('deals')
        .where('storeId', isEqualTo: storeId)
        .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('endDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Deal.fromFirestore(doc))
            .toList());
  }

  Stream<QuerySnapshot> getAllDeals() {
    return _firestore.collection('deals').snapshots();
  }

  Stream<QuerySnapshot> getFavoriteDeals(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots();
  }

  // Store Assets (Icons, Images)
  Future<String> uploadStoreAsset(String storeName, File file) async {
    final ref = _storage.ref().child('stores/$storeName/${DateTime.now()}.png');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<QuerySnapshot> searchStores(String query) {
    return _firestore
        .collection('stores')
        .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('name', isLessThan: query.toLowerCase() + 'z')
        .get();
  }

  // Add a deal to favorites
  Future<void> addToFavorites(String dealId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('favorites').add({
      'userId': userId,
      'dealId': dealId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String dealId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final querySnapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('dealId', isEqualTo: dealId)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Check if a deal is favorited
  Future<bool> isFavorited(String dealId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final querySnapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('dealId', isEqualTo: dealId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Update user preferences
  Future<void> updateUserPreferences({
    required String userId,
    String? language,
    String? currency,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
  }) async {
    final data = <String, dynamic>{};
    if (language != null) data['language'] = language;
    if (currency != null) data['currency'] = currency;
    if (notificationsEnabled != null) {
      data['notificationsEnabled'] = notificationsEnabled;
    }
    if (darkModeEnabled != null) data['darkModeEnabled'] = darkModeEnabled;

    await _firestore
        .collection('users')
        .doc(userId)
        .set({'preferences': data}, SetOptions(merge: true));
  }

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['preferences'] ?? {};
  }

  Future<void> addToCart(String userId, Deal deal) async {
    await _firestore.collection('carts').add({
      'userId': userId,
      'dealId': deal.id,
      'quantity': 1,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _firestore.collection('carts').doc(cartItemId).delete();
  }
} 