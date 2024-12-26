import 'package:cloud_firestore/cloud_firestore.dart';

class StoreItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final double? salePrice;
  final String imageUrl;
  final String unit;
  final bool inStock;
  int quantity;
  final String storeName;

  StoreItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.salePrice,
    required this.imageUrl,
    required this.unit,
    this.inStock = true,
    this.quantity = 0,
    required this.storeName,
  });

  factory StoreItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      salePrice: data['salePrice']?.toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      unit: data['unit'] ?? '',
      inStock: data['inStock'] ?? true,
      storeName: data['storeName'] ?? 'Unknown Store',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'salePrice': salePrice,
      'imageUrl': imageUrl,
      'unit': unit,
      'inStock': inStock,
      'storeName': storeName,
    };
  }

  factory StoreItem.fromMap(Map<String, dynamic> map) {
    return StoreItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      salePrice: map['salePrice']?.toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      unit: map['unit'] ?? '',
      inStock: map['inStock'] ?? true,
      quantity: map['quantity'] ?? 0,
      storeName: map['storeName'] ?? 'Unknown Store',
    );
  }
} 