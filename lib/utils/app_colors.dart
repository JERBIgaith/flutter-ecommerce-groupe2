import 'package:flutter/material.dart';

/// Application color constants for light and dark themes
class AppColors {
  // Primary brand color
  static const Color primary = Color(0xFF0B5D3B);

  // Light theme colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Colors.white;
  static const Color inputFillLight = Color(0xFFF3F4F6);
  static const Color inputBorderLight = Color(0xFFE5E7EB);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Dark theme colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color inputFillDark = Color(0xFF2D2D2D);
  static const Color inputBorderDark = Color(0xFF3F3F3F);
  static const Color textPrimaryDark = Color(0xFFE3F2FD);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);

  // Universal colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // Status colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusConfirmed = Color(0xFF3B82F6);
  static const Color statusShipped = Color(0xFF8B5CF6);
  static const Color statusDelivered = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Payment status colors
  static const Color paymentUnpaid = Color(0xFFF59E0B);
  static const Color paymentPending = Color(0xFF3B82F6);
  static const Color paymentPaid = Color(0xFF10B981);
  static const Color paymentFailed = Color(0xFFEF4444);
}
