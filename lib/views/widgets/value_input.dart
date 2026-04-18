import 'package:flutter/material.dart';
import 'package:uds/config/app_config.dart';

Widget buildDropdown({
  required String label,
  required String? value,
  required ValueChanged<String?> onChanged,
  required Map<String, String> dids,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppConfig.slate900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppConfig.slate800,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppConfig.emerald500,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            onChanged: onChanged,
            items: dids.keys.map((String name) {
              final hex = dids[name];
              return DropdownMenuItem<String>(
                value: name,
                child: Text("$hex - $name"),
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );
}

Widget buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        fontSize: 12,
      ),
    ),
  );
}

Widget buildDiagnosticCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppConfig.slate800,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white10),
    ),
    child: child,
  );
}
