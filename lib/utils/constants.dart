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

/// Format date time as dd/MM/yyyy HH:mm
String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return 'Just now';
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
