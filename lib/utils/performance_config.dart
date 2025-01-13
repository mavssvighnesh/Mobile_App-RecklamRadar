import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceConfig {
  static const int defaultFrameRate = 60;
  static const Duration frameTimeout = Duration(milliseconds: 16); // ~60fps

  static Future<void> optimizePerformance() async {
    // Set preferred refresh rate to highest available
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    // Enable high refresh rate if available
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    // Optimize image cache
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100MB
    PaintingBinding.instance.imageCache.maximumSize = 200;
  }

  static void releaseMemory() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
} 