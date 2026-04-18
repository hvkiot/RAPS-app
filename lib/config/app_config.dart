// config/app_config.dart
import 'package:flutter/material.dart';

class AppConfig {
  static const String serviceUuid = "12345678-1234-1234-1234-123456789ABC";
  static const String characteristicUuid = "87654321-4321-4321-4321-CBA987654321";
  
  // UDS Protocol Constants
  static const Duration bleTimeout = Duration(seconds: 10);
  static const Duration scanDuration = Duration(seconds: 5);
  static const Duration testerPresentInterval = Duration(seconds: 2);
  
  // Theme: Professional Dark Mode (Technician-grade)
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color cyan500 = Color(0xFF06B6D4);
}
