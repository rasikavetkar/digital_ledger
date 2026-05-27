import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF185FA5),
    brightness: Brightness.light,
  ),
  textTheme: GoogleFonts.nunitoTextTheme(),
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.black12, width: 0.5),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  ),
);

class AppColors {
  // Credit
  static const Color creditText = Color(0xFF3B6D11);
  static const Color creditBg = Color(0xFFEAF3DE);
  
  // Debit
  static const Color debitText = Color(0xFFA32D2D);
  static const Color debitBg = Color(0xFFFCEBEB);
  
  // Balance
  static const Color balanceText = Color(0xFF185FA5);
  
  // Primary
  static const Color primary = Color(0xFF185FA5);
}
