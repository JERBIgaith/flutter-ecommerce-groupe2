/// Application constants
class Constants {
  /// Currency code
  static const String currency = 'TND';
}

/// Format price with currency
String formatPrice(double price) {
  return '${price.toStringAsFixed(2)} ${Constants.currency}';
}
