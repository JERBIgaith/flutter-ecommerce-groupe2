/// Application constants
class Constants {
  /// Currency code
  static const String currency = 'TND';

  /// D17 Merchant Number
  static const String kD17MerchantNumber = '98765432';
}

/// Format price with currency
String formatPrice(double price) {
  return '${price.toStringAsFixed(2)} ${Constants.currency}';
}
