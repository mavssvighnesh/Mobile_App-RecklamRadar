import 'package:flutter_test/flutter_test.dart';
import 'package:recklamradar/utils/price_formatter.dart';

void main() {
  group('Price Formatting Tests', () {
    test('Formats price with SEK to INR conversion correctly', () {
      // Arrange
      double sekPrice = 100.0;
      double conversionRate = 7.89;
      String currencySymbol = '₹';

      // Act
      double inrPrice = sekPrice * conversionRate;
      String result = PriceFormatter.formatPrice(inrPrice, currencySymbol);

      // Assert
      expect(result, '₹789.00');
    });

    test('Formats small price correctly', () {
      // Arrange
      double price = 1.0;
      String currencySymbol = '₹';

      // Act
      String result = PriceFormatter.formatPrice(price, currencySymbol);

      // Assert
      expect(result, '₹1.00');
    });

    test('Formats large price correctly', () {
      // Arrange
      double price = 1000000.0;
      String currencySymbol = '₹';

      // Act
      String result = PriceFormatter.formatPrice(price, currencySymbol);

      // Assert
      expect(result, '₹1000000.00');
    });

    test('Handles zero price', () {
      // Arrange
      double price = 0.0;
      String currencySymbol = '₹';

      // Act
      String result = PriceFormatter.formatPrice(price, currencySymbol);

      // Assert
      expect(result, '₹0.00');
    });

    test('Throws error for negative price', () {
      // Arrange
      double price = -100.0;
      String currencySymbol = '₹';

      // Act & Assert
      expect(() => PriceFormatter.formatPrice(price, currencySymbol), throwsArgumentError);
    });
  });
} 