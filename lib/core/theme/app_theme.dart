import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color positive;
  final Color negative;
  final Color accent;
  final Color onAccent;

  const AppTheme({
    required this.name,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.positive,
    required this.negative,
    required this.accent,
    required this.onAccent,
  });

  static const brand = AppTheme(
    name: 'Auditra',
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF161616),
    border: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFF9A9A9A),
    positive: Color(0xFFCCFF33),
    negative: Color(0xFFFF4D4D),
    accent: Color(0xFFCCFF33),
    onAccent: Color(0xFF0A0A0A),
  );

  static const arbiter = AppTheme(
    name: 'Arbiter',
    background: Color(0xFF0B0E11),
    surface: Color(0xFF15181D),
    border: Color(0xFF2A2F38),
    textPrimary: Color(0xFFF5F6F7),
    textSecondary: Color(0xFF9098A3),
    positive: Color(0xFF16C784),
    negative: Color(0xFFEA3943),
    accent: Color(0xFF4C8DFF),
    onAccent: Colors.white,
  );

  static const all = [brand, arbiter];
}
