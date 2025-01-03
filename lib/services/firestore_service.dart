import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recklamradar/models/deal.dart';
import 'package:recklamradar/models/store.dart';
import 'package:recklamradar/models/store_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../constants/user_fields.dart';
import 'dart:convert';
import 'package:recklamradar/services/cache_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CacheService _cacheService = CacheService();

  static const String _cartKey = 'cached_cart';
  static const String _lastUpdateKey = 'cart_last_update';
  static const Duration _cacheDuration = Duration(minutes: 15);

  // User Profile Methods
  Future<void> createUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      print('Creating user profile: $data'); // Debug print
      
      final isAdmin = data[UserFields.isAdmin] ?? false;
      final collection = isAdmin ? 'admins' : 'users';
      
      // Ensure all required fields are present
      final userProfile = {
        UserFields.name: data[UserFields.name],
        UserFields.email: data[UserFields.email],
        UserFields.phone: data[UserFields.phone],
        UserFields.age: data[UserFields.age],
        UserFields.gender: data[UserFields.gender],
        UserFields.isBusiness: data[UserFields.isBusiness],
        UserFields.isAdmin: isAdmin,
        UserFields.profileImage: data[UserFields.profileImage],
        UserFields.createdAt: data[UserFields.createdAt] ?? FieldValue.serverTimestamp(),
        UserFields.updatedAt: data[UserFields.updatedAt] ?? FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection(collection).doc(userId).set(
        userProfile,
        SetOptions(merge: true),
      );
      
      print('User profile created successfully'); // Debug print
    } catch (e) {
      print('Error in createUserProfile: $e'); // Debug print
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      print('Getting user profile for ID: $userId'); // Debug print
      
      // Check users collection first
      var userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        print('Found user in users collection: ${userDoc.data()}'); // Debug print
        return userDoc.data();
      }
      
      // If not found in users, check admins collection
      var adminDoc = await _firestore.collection('admins').doc(userId).get();
      
      if (adminDoc.exists) {
        print('Found user in admins collection: ${adminDoc.data()}'); // Debug print
        return {
          ...adminDoc.data()!,
          'isAdmin': true,
        };
      }
      
      print('No user document found'); // Debug print
      return null;
    } catch (e) {
      print('Error in getUserProfile: $e'); // Debug print
      rethrow;
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
        .where('name', isLessThan: '${query.toLowerCase()}z')
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

  Future<void> addToCart(String userId, StoreItem item, String storeName) async {
    try {
      print('Adding to cart: ${item.name} for user: $userId in store: $storeName'); // Debug print
      
      // Check if item already exists in cart
      final existingItems = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .where('name', isEqualTo: item.name)
          .where('storeName', isEqualTo: storeName)
          .get();

      if (existingItems.docs.isNotEmpty) {
        // Update quantity if item exists
        final existingItem = existingItems.docs.first;
        final currentQuantity = existingItem.data()['quantity'] ?? 0;
        await existingItem.reference.update({
          'quantity': currentQuantity + item.quantity,
        });
      } else {
        // Add new item if it doesn't exist
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .add({
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'storeName': storeName,
          'imageUrl': item.imageUrl,
          'picked': false,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      print('Successfully added to cart'); // Debug print
    } catch (e) {
      print('Error adding to cart: $e'); // Debug print
      rethrow;
    }
  }

  Future<void> removeFromCart(String userId, String itemId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId)
        .delete();
  }

  Future<List<StoreItem>> getStoreItems(String storeId) async {
    try {
      final cachedItems = await _cacheService.getCachedStoreItems(storeId);
      if (cachedItems != null) {
        return cachedItems.map((item) {
          final mapItem = item as Map<String, dynamic>;
          mapItem['id'] = mapItem['id'] ?? '';
          return StoreItem.fromMap(mapItem);
        }).toList();
      }

      // If no cache, fetch from Firestore
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('items')
          .orderBy('category')
          .get();

      final items = snapshot.docs
          .map((doc) => StoreItem.fromFirestore(doc))
          .toList();

      // Cache the fetched data
      await _cacheService.cacheStoreItems(
        storeId,
        items.map((item) => item.toMap()).toList(),
      );

      return items;
    } catch (e) {
      print('Error getting store items: $e');
      return [];
    }
  }

  // Get cart items stream
  Stream<List<Map<String, dynamic>>> getCartItems(String userId) async* {
    if (await isCacheValid()) {
      yield await getCachedCartItems();
    }

    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'price': (data['price'] ?? 0.0).toDouble(),
          'quantity': data['quantity'] ?? 1,
          'storeName': data['storeName'] ?? 'Unknown Store',
          'imageUrl': data['imageUrl'] ?? '',
          'picked': data['picked'] ?? false,
        };
      }).toList();
      
      // Save items locally
      saveCartItemsLocally(userId, items);
      return items;
    });
  }

  Future<void> updateCartItemPicked(String userId, String itemId, bool picked) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId)
        .update({'picked': picked});
  }

  Future<void> updateCartItemQuantity(String userId, String itemId, int quantity) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId)
        .update({'quantity': quantity});
  }

  // Add method to save cart items locally
  Future<void> saveCartItemsLocally(String userId, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(items));
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch - lastUpdate < _cacheDuration.inMilliseconds;
  }

  Future<List<Map<String, dynamic>>> getCachedCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cartKey);
    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(
        jsonDecode(cachedData).map((x) => Map<String, dynamic>.from(x))
      );
    }
    return [];
  }

  Stream<Map<String, dynamic>> getCartItemStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      Map<String, dynamic> cartItems = {};
      for (var doc in snapshot.docs) {
        cartItems[doc.id] = {
          ...doc.data(),
          'id': doc.id,
        };
      }
      return cartItems;
    });
  }
} 