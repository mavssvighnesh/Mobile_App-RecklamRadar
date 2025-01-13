import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static const String _storeItemsKey = 'store_items_';
  static const String _lastFetchKey = 'last_fetch_';
  static const Duration _cacheDuration = Duration(minutes: 15);

  Future<void> cacheStoreItems(String storeId, List<dynamic> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeItemsKey + storeId, jsonEncode(items));
    await prefs.setInt(
      _lastFetchKey + storeId,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<List<dynamic>?> getCachedStoreItems(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getInt(_lastFetchKey + storeId);
    
    if (lastFetch == null) return null;
    
    final isCacheValid = DateTime.now().millisecondsSinceEpoch - lastFetch < 
        _cacheDuration.inMilliseconds;
    
    if (!isCacheValid) return null;
    
    final cachedData = prefs.getString(_storeItemsKey + storeId);
    if (cachedData != null) {
      return jsonDecode(cachedData);
    }
    return null;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_storeItemsKey) || key.startsWith(_lastFetchKey)) {
        await prefs.remove(key);
      }
    }
  }
} 