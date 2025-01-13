import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class SharedWidgets {
  static Widget loadingIndicator({Color? color}) => Center(
    child: CircularProgressIndicator(
      color: color ?? AppStyles.primaryColor,
    ),
  );

  static Widget errorWidget(String message, VoidCallback onRetry) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, style: AppStyles.body),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  static Widget emptyStateWidget(String message) => Center(
    child: Text(message, style: AppStyles.body),
  );
} 