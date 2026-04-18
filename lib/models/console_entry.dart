// models/console_entry.dart
// ---------------------------------------------------------------------------
// Represents a single line in the log console. Each entry carries a timestamp,
// a severity/type, the hex payload and an optional decoded ASCII value.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// The kind of log entry – drives icon and colour in the console.
enum ConsoleEntryType {
  sent,     // command sent to ECU  → cyan
  success,  // positive response    → green
  error,    // negative response    → red
  info,     // informational        → grey
}

class ConsoleEntry {
  final DateTime timestamp;
  final ConsoleEntryType type;
  final String message;
  final String? hexData;
  final String? asciiValue;

  ConsoleEntry({
    required this.type,
    required this.message,
    this.hexData,
    this.asciiValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Formatted time string for the console prefix.
  String get timeString {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Colour associated with this entry type.
  Color get color {
    switch (type) {
      case ConsoleEntryType.sent:
        return const Color(0xFF06B6D4); // cyan
      case ConsoleEntryType.success:
        return const Color(0xFF10B981); // green
      case ConsoleEntryType.error:
        return const Color(0xFFF43F5E); // red
      case ConsoleEntryType.info:
        return Colors.grey;
    }
  }

  /// Leading icon for visual scanning.
  IconData get icon {
    switch (type) {
      case ConsoleEntryType.sent:
        return Icons.arrow_upward_rounded;
      case ConsoleEntryType.success:
        return Icons.check_circle_outline_rounded;
      case ConsoleEntryType.error:
        return Icons.error_outline_rounded;
      case ConsoleEntryType.info:
        return Icons.info_outline_rounded;
    }
  }
}
