import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final _connectivity = Connectivity();
  
  Future<bool> hasNetworkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<bool> hasHighBandwidth() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.wifi || 
           result == ConnectivityResult.ethernet;
  }

  // Adjust image quality based on network
  int getOptimalImageQuality() {
    if (kIsWeb) return 85;
    return 70;
  }

  // Get optimal cache duration based on network
  Duration getOptimalCacheDuration() {
    return const Duration(days: 7);
  }
} 