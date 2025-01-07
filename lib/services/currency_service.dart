import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  final _currencyController = StreamController<String>.broadcast();
  Stream<String> get currencyStream => _currencyController.stream;

  static const String _baseUrl = 'http://apilayer.net/api/live';
  static const String _apiKey = '1qflRbfP5gbNMfaNSrOU53mC7RAF4oFn';
  static const String _baseCurrency = 'SEK';  // Base currency is SEK
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
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString('selected_currency') ?? 'SEK';
    await _loadExchangeRates();
  }

  Future<void> _loadExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSuccessfulFetch = prefs.getString(_lastSuccessfulFetchKey);
      final now = DateTime.now();
      
      // Load cached rates first
      final cachedRates = prefs.getString(_prefsKey);
      if (cachedRates != null) {
        _exchangeRates = Map<String, double>.from(
          json.decode(cachedRates).map((key, value) => 
            MapEntry(key, double.parse(value.toString()))));
        print('Loaded cached exchange rates: $_exchangeRates');
      }

      // Determine if we should fetch new rates
      bool shouldFetchNewRates = false;
      if (lastSuccessfulFetch == null) {
        print('No previous successful fetch found');
        shouldFetchNewRates = true;
      } else {
        final lastFetch = DateTime.parse(lastSuccessfulFetch);
        final timeSinceLastFetch = now.difference(lastFetch);
        
        if (timeSinceLastFetch >= _fetchCooldown) {
          print('Last successful fetch was ${timeSinceLastFetch.inHours} hours ago');
          shouldFetchNewRates = true;
        } else {
          print('Using cached rates, next fetch in ${(_fetchCooldown - timeSinceLastFetch).inHours} hours');
        }
      }

      if (shouldFetchNewRates) {
        print('Attempting to fetch new exchange rates...');
        final success = await _fetchLatestRates();
        
        if (success) {
          // Only update the last fetch time if the fetch was successful
          await prefs.setString(_lastSuccessfulFetchKey, now.toIso8601String());
          print('Updated last successful fetch timestamp');
        }
      }
    } catch (e) {
      print('Error in _loadExchangeRates: $e');
      _useBackupRates();
    }
  }

  // Updated conversion rates with more precise values
  final Map<String, double> _conversionRates = {
    'SEK': 1.0,
    'USD': 0.095,  // Example: 1 SEK = 0.095 USD
    'EUR': 0.087,  // Example: 1 SEK = 0.087 EUR
    'INR': 7.89,   // Example: 1 SEK = 7.89 INR
  };

  Future<bool> _fetchLatestRates() async {
    try {
      print('Making API call to fetch latest rates...');
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
          
          // Calculate and store the conversion rates
          _exchangeRates = {
            'SEK': 1.0,
            'USD': 1.0 / (quotes['USDSEK']?.toDouble() ?? 10.5),
            'EUR': (quotes['USDEUR']?.toDouble() ?? 0.92) / (quotes['USDSEK']?.toDouble() ?? 10.5),
            'INR': (quotes['USDINR']?.toDouble() ?? 83.0) / (quotes['USDSEK']?.toDouble() ?? 10.5),
          };
          
          print('New rates fetched successfully: $_exchangeRates');
          
          // Cache the new rates
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsKey, json.encode(_exchangeRates));
          print('New rates cached successfully');
          return true;
        } else {
          print('API Error: ${data['error']?['info']}');
          throw Exception('API returned error: ${data['error']?['info']}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode} error');
      }
    } catch (e) {
      print('Error fetching rates: $e');
      _useBackupRates();
      return false;
    }
  }

  void _useBackupRates() {
    // Backup rates if API fails
    _exchangeRates = {
      'SEK': 1.0,
      'USD': 0.095,  // 1 SEK ≈ 0.095 USD
      'EUR': 0.087,  // 1 SEK ≈ 0.087 EUR
      'INR': 7.89,   // 1 SEK ≈ 7.89 INR
    };
    print('Using backup exchange rates: $_exchangeRates');
  }

  Future<void> setSelectedCurrency(String currency) async {
    _selectedCurrency = currency;
    _currencyController.add(currency);
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currency);
  }

  // Update the convertPrice method
  double convertPrice(double sekPrice) {
    final rate = _exchangeRates?[_selectedCurrency] ?? 1.0;
    return roundToTwoDecimals(sekPrice * rate);
  }

  String formatPrice(double price) {
    // Format with proper currency symbols and positions
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
        return '${price.toStringAsFixed(2)} ${_currencySymbols[_selectedCurrency]}';
    }
  }

  String formatPriceWithCurrency(double price) {
    return '${formatPrice(price)} ($_selectedCurrency)';
  }

  // Only use this for manual refresh if needed
  Future<void> forceRefreshRates() async {
    print('Force refreshing rates (use sparingly)');
    await _fetchLatestRates();
  }

  // Add method to notify when currency changes
  void notifyPriceChange() {
    // This could be used to trigger UI updates when currency changes
    print('Currency changed to $_selectedCurrency');
  }

  // Add this method to manually refresh rates
  Future<void> refreshRates() async {
    print('Manually refreshing rates...');
    await _fetchLatestRates();
  }

  // Add this method to round converted prices
  double roundToTwoDecimals(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  // Add method to convert between currencies
  double convertBetweenCurrencies(double amount, String fromCurrency, String toCurrency) {
    // First convert to SEK (our base currency)
    double sekAmount = amount;
    if (fromCurrency != 'SEK') {
      sekAmount = amount / (_exchangeRates?[fromCurrency] ?? 1.0);
    }
    
    // Then convert from SEK to target currency
    if (toCurrency == 'SEK') {
      return roundToTwoDecimals(sekAmount);
    }
    return roundToTwoDecimals(sekAmount * (_exchangeRates?[toCurrency] ?? 1.0));
  }

  // Add method to store budget with currency
  Future<void> saveBudget(double amount, String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_amount', amount);
    await prefs.setString('budget_currency', currency);
  }

  // Add method to load budget with currency
  Future<Map<String, dynamic>> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final amount = prefs.getDouble('budget_amount');
    final currency = prefs.getString('budget_currency') ?? 'SEK';
    return {
      'amount': amount,
      'currency': currency,
    };
  }

  // Add this setter
  set selectedCurrency(String currency) {
    _selectedCurrency = currency;
  }

  // Add this setter for testing purposes
  @visibleForTesting
  set exchangeRates(Map<String, double>? rates) {
    _exchangeRates = rates;
  }
}