import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recklamradar/services/currency_service.dart';
import '../utils/price_formatter.dart';

class StoreItem {
  final String id;
  final String name;
  final String category;
  final double _basePriceSEK;  // Original price in SEK
  final double? _baseSalePriceSEK;  // Original sale price in SEK
  final String imageUrl;
  final String unit;
  final bool inStock;
  int quantity;
  final String storeName;

  // Dynamic getters that convert SEK to current currency
  double get price {
    final currencyService = CurrencyService();
    final convertedPrice = currencyService.convertPrice(_basePriceSEK);
    print('Converting price from $_basePriceSEK SEK to ${currencyService.selectedCurrency}: $convertedPrice');
    return convertedPrice;
  }

  double? get salePrice {
    if (_baseSalePriceSEK == null) return null;
    final currencyService = CurrencyService();
    final convertedPrice = currencyService.convertPrice(_baseSalePriceSEK);
    print('Converting sale price from $_baseSalePriceSEK SEK to ${currencyService.selectedCurrency}: $convertedPrice');
    return convertedPrice;
  }

  // Original SEK prices for reference
  double get originalPriceSEK => _basePriceSEK;
  double? get originalSalePriceSEK => _baseSalePriceSEK;

  StoreItem({
    required this.id,
    required this.name,
    required this.category,
    required double price,
    double? salePrice,
    required this.imageUrl,
    required this.unit,
    this.inStock = true,
    this.quantity = 0,
    required this.storeName,
  }) : _basePriceSEK = price,
       _baseSalePriceSEK = salePrice;

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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': _basePriceSEK,  // Store original SEK price
      'salePrice': _baseSalePriceSEK,  // Store original SEK sale price
      'imageUrl': imageUrl,
      'unit': unit,
      'inStock': inStock,
      'storeName': storeName,
    };
  }

  StoreItem copyWith({
    String? id,
    String? name,
    String? category,
    String? imageUrl,
    double? price,
    double? salePrice,
    String? unit,
    String? storeName,
  }) {
    return StoreItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      salePrice: salePrice ?? this.salePrice,
      storeName: storeName ?? this.storeName,
    );
  }

  String get formattedPrice => PriceFormatter.formatPriceWithUnit(
    price, 
    unit,
    salePrice: salePrice,
  );

  String get formattedUnitPrice => '${price.toStringAsFixed(2)} SEK/${PriceFormatter.formatUnit(unit)}';
} 