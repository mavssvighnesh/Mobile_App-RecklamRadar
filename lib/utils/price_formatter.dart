  import '../services/currency_service.dart';

class PriceFormatter {
  static String formatPriceWithUnit(double price, String unit, {double? salePrice}) {
    final currency = CurrencyService().selectedCurrency;
    final formattedPrice = price.toStringAsFixed(2);
    final formattedUnit = formatUnit(unit);
    
    if (salePrice != null) {
      final formattedSalePrice = salePrice.toStringAsFixed(2);
      return '$formattedSalePrice $currency/$formattedUnit\n(Reg: $formattedPrice $currency/$formattedUnit)';
    }
    
    return '$formattedPrice $currency/$formattedUnit';
  }

  static String formatUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
      case 'kilo':
      case 'kilogram':
        return 'kg';
      case 'st':
      case 'piece':
      case 'pieces':
        return 'st';
      case 'g':
      case 'gram':
      case 'grams':
        return 'g';
      case 'l':
      case 'liter':
      case 'liters':
        return 'L';
      case 'ml':
      case 'milliliter':
        return 'ml';
      case 'pack':
      case 'pk':
        return 'pk';
      default:
        return unit;
    }
  }
} 