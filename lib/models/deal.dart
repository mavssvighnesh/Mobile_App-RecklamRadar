import 'package:cloud_firestore/cloud_firestore.dart';

class Deal {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? memberPrice;
  final DateTime startDate;
  final DateTime endDate;
  final String category;

  var store;

  Deal({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.memberPrice,
    required this.startDate,
    required this.endDate,
    required this.category,
  });

  factory Deal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Deal(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] as num).toDouble(),
      memberPrice: (data['memberPrice'] as num?)?.toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'memberPrice': memberPrice,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'category': category,
    };
  }
} 