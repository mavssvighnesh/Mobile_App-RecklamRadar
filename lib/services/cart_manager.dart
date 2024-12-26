import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_item.dart';

class CartManager {
  final SharedPreferences _prefs;
  static const String _cartKey = 'cart_items';

  CartManager(this._prefs);

  Future<void> addToCart(StoreItem item, String storeId) async {
    final cartItems = _prefs.getStringList(_cartKey) ?? [];
    cartItems.add('${item.id}:$storeId');
    await _prefs.setStringList(_cartKey, cartItems);
  }

  Future<void> removeFromCart(String itemId, String storeId) async {
    final cartItems = _prefs.getStringList(_cartKey) ?? [];
    cartItems.remove('$itemId:$storeId');
    await _prefs.setStringList(_cartKey, cartItems);
  }
} 