import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final Map<String, dynamic> metadata;
  final String userId;

  Store({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    this.metadata = const {},
    required this.userId,
  });

  factory Store.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      metadata: data['metadata'] ?? {},
      userId: data['userId'] ?? '',
    );
  }
  

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'metadata': metadata,
      'userId': userId,
    };
  }
} 