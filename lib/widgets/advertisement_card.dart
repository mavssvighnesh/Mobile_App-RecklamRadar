import 'package:flutter/material.dart';
import '../models/advertisement.dart';

class AdvertisementCard extends StatelessWidget {
  final Advertisement advertisement;

  const AdvertisementCard({super.key, required this.advertisement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: advertisement.imageUrl.isNotEmpty
            ? Image.network(advertisement.imageUrl, width: 60, height: 60)
            : const Icon(Icons.image, size: 60),
        title: Text(advertisement.title),
        subtitle: Text(advertisement.description),
        trailing: Text('${advertisement.price ?? 0} SEK'),
      ),
    );
  }
} 