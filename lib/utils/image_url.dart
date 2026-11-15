/// Image URL utilities for validation and normalization
class ImageUrl {
  /// Trim whitespace from URL
  static String trim(String url) {
    return url.trim();
  }

  /// Force HTTPS protocol
  static String forceHttps(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  /// Convert Google Drive view links to direct image links
  /// From: https://drive.google.com/file/d/FILE_ID/view
  /// To: https://drive.google.com/uc?export=view&id=FILE_ID
  static String convertGoogleDrive(String url) {
    final driveRegex = RegExp(r'drive\.google\.com/file/d/([^/]+)');
    final match = driveRegex.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return url;
  }

  /// Convert Dropbox share links to direct image links
  /// From: https://www.dropbox.com/...?dl=0
  /// To: https://www.dropbox.com/...?raw=1
  static String convertDropbox(String url) {
    if (url.contains('dropbox.com') && url.contains('dl=0')) {
      return url.replaceAll('dl=0', 'raw=1');
    }
    return url;
  }

  /// Normalize URL: trim, force HTTPS, convert special links
  static String normalize(String url) {
    String normalized = trim(url);
    normalized = forceHttps(normalized);
    normalized = convertGoogleDrive(normalized);
    normalized = convertDropbox(normalized);
    return normalized;
  }

  /// Validate image URL and return clear error message
  static String? validate(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'Image URL is required';
    }

    final trimmed = url.trim();

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }

    // Basic URL pattern check
    final urlPattern = RegExp(
      r'^https?://[^\s/$.?#].[^\s]*$',
      caseSensitive: false,
    );

    if (!urlPattern.hasMatch(trimmed)) {
      return 'Please enter a valid URL';
    }

    return null;
  }
}
