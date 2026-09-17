import 'package:flutter/material.dart';

Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  String value = hex.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 6) {
    value = 'FF$value';
  }
  if (value.length != 8) return null;
  final int? parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

Color parseHexColorOr(String? hex, Color fallback) {
  return parseHexColor(hex) ?? fallback;
}
