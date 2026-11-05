import 'package:flutter/material.dart';

class AppTheme {
  static const String fontFamily = 'AppFont';

  // 品牌核心渐变色
  static const Color primaryGradientStart = Color(0xFF5B5FEF);
  static const Color primaryGradientMiddle = Color(0xFF8B5CF6);
  static const Color primaryGradientEnd = Color(0xFFEC4899);

  // 状态强调色
  static const Color alertOrange = Color(0xFFF97316);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color overdueRed = Color(0xFFEF4444);

  // 品牌色渐变装饰
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientMiddle, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorSchemeSeed: primaryGradientStart,
      brightness: Brightness.light,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorSchemeSeed: primaryGradientStart,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF171A21),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
