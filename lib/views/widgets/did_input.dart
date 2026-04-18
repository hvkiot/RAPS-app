import 'package:flutter/material.dart';
import 'package:uds/config/app_config.dart';

InputDecoration inputDecoration(String label, String hint) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: Colors.white54),
    hintStyle: const TextStyle(color: Colors.white24),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.white10),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: AppConfig.emerald500),
    ),
  );
}
