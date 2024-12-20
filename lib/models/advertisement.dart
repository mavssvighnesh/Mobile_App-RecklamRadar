import 'package:cloud_firestore/cloud_firestore.dart';

class Advertisement {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String userId;
  final String category;
  final DateTime createdAt;
  final GeoPoint? location;
  final double? price;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.userId,
    required this.category,
    required this.createdAt,
    this.location,
    this.price,
  });

  factory Advertisement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Advertisement(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint?,
      price: (data['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'userId': userId,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'price': price,
    };
  }
} 