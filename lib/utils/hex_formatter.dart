// utils/hex_formatter.dart

import 'package:flutter/services.dart';

class HexInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-hex characters
    final text = newValue.text
        .replaceAll(RegExp(r'[^0-9a-fA-F]'), '')
        .toUpperCase();

    final StringBuffer newText = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      newText.write(text[i]);
      // Add a space after every 2 characters, but not after the last character
      if ((i + 1) % 2 == 0 && i != text.length - 1) {
        newText.write(' ');
      }
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

int getRequiredLength(String did) {
  String cleanDid = did.replaceAll('0x', '').toUpperCase();

  switch (cleanDid) {
    case "F187":
    case "F188":
    case "F191":
    case "F1A0":
      return 15; // 15 bytes

    case "F190":
    case "F1A1":
      return 17; // 17 bytes

    case "F1A6":
      return 20; // 20 bytes

    case "220D":
    case "220E":
    case "F18C":
    case "F192":
      return 4; // 4 bytes

    case "220F":
    case "2210":
    case "2211":
    case "2212":
    case "2213":
    case "2214":
    case "2215":
    case "2216":
    case "2217":
    case "2218":
    case "2219":
    case "221A":
    case "221B":
    case "221C":
      return 2; // 2 bytes (16-bit integers)

    default:
      return 0; // Auto-detect
  }
}

bool isNumericDid(String did) {
  String cleanDid = did.replaceAll('0x', '').toUpperCase();

  const numericDids = [
    "220F",
    "2210",
    "2211",
    "2212",
    "2213",
    "2214",
    "2215",
    "2216",
    "2217",
    "2218",
    "2219",
    "221A",
    "221B",
    "221C",
    "F18C",
    "F192",
  ];
  return numericDids.contains(cleanDid);
}
