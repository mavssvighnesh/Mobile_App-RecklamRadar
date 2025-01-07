import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CurrencyServiceException implements Exception {
  final String message;
  CurrencyServiceException(this.message);
  @override
  String toString() => 'CurrencyServiceException: $message';
}

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  final _currencyController = StreamController<String>.broadcast();
  Stream<String> get currencyStream => _currencyController.stream;

  static const String _baseUrl = 'http://apilayer.net/api/live';
  static const String _apiKey = '1qflRbfP5gbNMfaNSrOU53mC7RAF4oFn';
  static const String _baseCurrency = 'SEK';
  static const String _prefsKey = 'exchange_rates';
  static const String _lastFetchDateKey = 'last_fetch_date';
  static const String _lastSuccessfulFetchKey = 'last_successful_fetch';
  static const Duration _fetchCooldown = Duration(hours: 24);
  
  final Map<String, String> _currencySymbols = {
    'SEK': 'kr',
    'USD': '\$',
    'EUR': '€',
    'INR': '₹',
  };

  Map<String, double>? _exchangeRates;
  String _selectedCurrency = 'SEK';

  String get selectedCurrency => _selectedCurrency;
  String get currencySymbol => _currencySymbols[_selectedCurrency] ?? '';

  Future<void> initializeCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('selected_currency');
      
      if (savedCurrency != null && _isValidCurrency(savedCurrency)) {
        _selectedCurrency = savedCurrency;
      } else {
        _selectedCurrency = 'SEK';
        await prefs.setString('selected_currency', 'SEK');
      }
      
      await _loadExchangeRates();
    } catch (e) {
      print('Error initializing currency service: $e');
      throw CurrencyServiceException('Failed to initialize currency service');
    }
  }

  Future<void> _loadExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSuccessfulFetch = prefs.getString(_lastSuccessfulFetchKey);
      final now = DateTime.now();
      
      final cachedRates = prefs.getString(_prefsKey);
      if (cachedRates != null) {
        _exchangeRates = Map<String, double>.from(
          json.decode(cachedRates).map((key, value) => 
            MapEntry(key, double.parse(value.toString()))));
      }

      bool shouldFetchNewRates = false;
      if (lastSuccessfulFetch == null) {
        shouldFetchNewRates = true;
      } else {
        final lastFetch = DateTime.parse(lastSuccessfulFetch);
        final timeSinceLastFetch = now.difference(lastFetch);
        shouldFetchNewRates = timeSinceLastFetch >= _fetchCooldown;
      }

      if (shouldFetchNewRates) {
        final success = await _fetchLatestRates();
        if (success) {
          await prefs.setString(_lastSuccessfulFetchKey, now.toIso8601String());
        }
      }
    } catch (e) {
      print('Error in _loadExchangeRates: $e');
      _useBackupRates();
    }
  }

  final Map<String, double> _conversionRates = {
    'SEK': 1.0,
    'USD': 0.095,
    'EUR': 0.087,
    'INR': 7.89,
  };

  Future<bool> _fetchLatestRates() async {
    try {
      final response = await http.get(Uri.parse(
        '$_baseUrl?access_key=$_apiKey&currencies=EUR,USD,INR&source=SEK&format=1'
      )).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('API request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final quotes = data['quotes'] as Map<String, dynamic>;
          
          _exchangeRates = {
            'SEK': 1.0,
            'USD': 1.0 / (quotes['USDSEK']?.toDouble() ?? 10.5),
            'EUR': (quotes['USDEUR']?.toDouble() ?? 0.92) / (quotes['USDSEK']?.toDouble() ?? 10.5),
            'INR': (quotes['USDINR']?.toDouble() ?? 83.0) / (quotes['USDSEK']?.toDouble() ?? 10.5),
          };
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsKey, json.encode(_exchangeRates));
          return true;
        }
        throw Exception('API returned error: ${data['error']?['info']}');
      }
      throw Exception('HTTP ${response.statusCode} error');
    } catch (e) {
      print('Error fetching rates: $e');
      _useBackupRates();
      return false;
    }
  }

  void _useBackupRates() {
    _exchangeRates = {
      'SEK': 1.0,
      'USD': 0.095,
      'EUR': 0.087,
      'INR': 7.89,
    };
  }

  Future<void> setSelectedCurrency(String currency) async {
    _selectedCurrency = currency;
    _currencyController.add(currency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currency);
  }

  double convertPrice(double sekPrice) {
    if (sekPrice.isNaN || sekPrice.isInfinite) {
      return 0.0;
    }
    
    try {
      final rate = _exchangeRates?[_selectedCurrency];
      if (!_isValidRate(rate)) {
        return sekPrice;
      }
      return roundToTwoDecimals(sekPrice * rate!);
    } catch (e) {
      print('Error converting price: $e');
      return sekPrice;
    }
  }

  String formatPrice(double price) {
    if (price.isNaN || price.isInfinite) {
      return '0.00';
    }
    
    try {
      final symbol = _currencySymbols[_selectedCurrency];
      if (symbol == null) {
        return '${price.toStringAsFixed(2)} $_selectedCurrency';
      }
      
      switch (_selectedCurrency) {
        case 'SEK':
          return '${price.toStringAsFixed(2)} kr';
        case 'EUR':
          return '€${price.toStringAsFixed(2)}';
        case 'USD':
          return '\$${price.toStringAsFixed(2)}';
        case 'INR':
          return '₹${price.toStringAsFixed(2)}';
        default:
          return '${price.toStringAsFixed(2)} $symbol';
      }
    } catch (e) {
      return price.toStringAsFixed(2);
    }
  }

  String formatPriceWithCurrency(double price) {
    return '${formatPrice(price)} ($_selectedCurrency)';
  }

  Future<void> forceRefreshRates() async {
    await _fetchLatestRates();
  }

  void notifyPriceChange() {
    print('Currency changed to $_selectedCurrency');
  }

  Future<void> refreshRates() async {
    await _fetchLatestRates();
  }

  double roundToTwoDecimals(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }
    try {
      return double.parse(value.toStringAsFixed(2));
    } catch (e) {
      return value;
    }
  }

  double convertBetweenCurrencies(double amount, String fromCurrency, String toCurrency) {
    try {
      if (amount.isNaN || amount.isInfinite) {
        throw CurrencyServiceException('Invalid amount: $amount');
      }
      
      if (!_isValidCurrency(fromCurrency) || !_isValidCurrency(toCurrency)) {
        throw CurrencyServiceException('Invalid currency provided');
      }
      
      fromCurrency = fromCurrency.toUpperCase();
      toCurrency = toCurrency.toUpperCase();
      
      double sekAmount = amount;
      if (fromCurrency != 'SEK') {
        final fromRate = _exchangeRates?[fromCurrency];
        if (!_isValidRate(fromRate)) {
          throw CurrencyServiceException('Invalid exchange rate for $fromCurrency');
        }
        sekAmount = amount / fromRate!;
      }
      
      if (toCurrency == 'SEK') {
        return roundToTwoDecimals(sekAmount);
      }
      
      final toRate = _exchangeRates?[toCurrency];
      if (!_isValidRate(toRate)) {
        throw CurrencyServiceException('Invalid exchange rate for $toCurrency');
      }
      
      return roundToTwoDecimals(sekAmount * toRate!);
    } catch (e) {
      print('Error converting between currencies: $e');
      return amount;
    }
  }

  Future<void> saveBudget(double amount, String currency) async {
    try {
      if (amount.isNaN || amount.isInfinite || amount < 0) {
        throw CurrencyServiceException('Invalid budget amount: $amount');
      }
      
      if (!_isValidCurrency(currency)) {
        throw CurrencyServiceException('Invalid currency for budget: $currency');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('budget_amount', amount);
      await prefs.setString('budget_currency', currency.toUpperCase());
    } catch (e) {
      throw CurrencyServiceException('Failed to save budget: $e');
    }
  }

  Future<Map<String, dynamic>> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final amount = prefs.getDouble('budget_amount');
    final currency = prefs.getString('budget_currency') ?? 'SEK';
    return {
      'amount': amount,
      'currency': currency,
    };
  }

  set selectedCurrency(String currency) {
    _selectedCurrency = currency;
  }

  @visibleForTesting
  set exchangeRates(Map<String, double>? rates) {
    _exchangeRates = rates;
  }

  bool _isValidCurrency(String currency) {
    return _currencySymbols.containsKey(currency.toUpperCase());
  }

  bool _isValidRate(dynamic rate) {
    if (rate == null) return false;
    if (rate is! num) return false;
    return !rate.isNaN && !rate.isInfinite && rate > 0;
  }

  bool _validateExchangeRates(Map<String, dynamic> rates) {
    try {
      for (final entry in rates.entries) {
        if (!_isValidCurrency(entry.key) || !_isValidRate(entry.value)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}