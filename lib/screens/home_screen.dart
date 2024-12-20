import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recklamradar/home_screen.dart';
import 'package:recklamradar/models/advertisement.dart';
import 'package:recklamradar/services/firestore_service.dart';
import '../widgets/advertisement_card.dart';

class _UserHomeScreenState extends State<UserHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... other scaffold properties
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getAdvertisements(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final ads = snapshot.data?.docs
              .map((doc) => Advertisement.fromFirestore(doc))
              .toList() ?? [];

          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return AdvertisementCard(advertisement: ad);
            },
          );
        },
      ),
    );
  }
} 