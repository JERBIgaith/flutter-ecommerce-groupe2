/// Validation utilities for form fields
class Validators {
  /// Validates if a field is not empty
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates password (minimum 6 characters)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  /// Validates if password confirmation matches the original password
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates name field
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }

  /// Validates delivery address (required, 5 to 200 characters)
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Delivery address is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 5) {
      return 'Address must be at least 5 characters';
    }
    if (trimmed.length > 200) {
      return 'Address must be at most 200 characters';
    }
    return null;
  }

  /// Validates Tunisian phone number
  /// Accepts optional +216 prefix, 8 digits starting with 2, 4, 5, 7, or 9
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    String cleaned = value.trim().replaceAll(RegExp(r'\s+|-'), '');
    if (cleaned.startsWith('+216')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.length == 11 && cleaned.startsWith('216')) {
      cleaned = cleaned.substring(3);
    }
    final phoneRegex = RegExp(r'^[24579]\d{7}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Enter a valid 8-digit Tunisian phone number';
    }
    return null;
  }

  /// Formats/cleans a Tunisian phone number
  static String formatTunisianPhone(String value) {
    String cleaned = value.trim().replaceAll(RegExp(r'\s+|-'), '');
    if (cleaned.startsWith('+216')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.length == 11 && cleaned.startsWith('216')) {
      cleaned = cleaned.substring(3);
    }
    return cleaned;
  }

  /// Validates D17 transaction reference (required, 4 to 40 characters)
  static String? d17Reference(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Transaction reference is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 4 || trimmed.length > 40) {
      return 'Reference must be between 4 and 40 characters';
    }
    return null;
  }
}
