import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassSnackBar extends SnackBar {
  GlassSnackBar({
    super.key,
    required String message,
    bool isSuccess = true,
    Duration duration = const Duration(seconds: 3),
  }) : super(
          content: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        );
} 