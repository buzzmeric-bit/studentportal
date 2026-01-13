import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Colors - Modern 2026 blue gradient
  static const Color primary = Color(0xFF4F46E5);           // Indigo 600
  static const Color primaryLight = Color(0xFF818CF8);      // Indigo 400
  static const Color primaryDark = Color(0xFF3730A3);       // Indigo 800
  
  // Secondary Colors - Complementary teal
  static const Color secondary = Color(0xFF14B8A6);         // Teal 500
  static const Color secondaryLight = Color(0xFF5EEAD4);    // Teal 300
  static const Color secondaryDark = Color(0xFF0F766E);     // Teal 700
  
  // Accent Colors - Vibrant coral
  static const Color accent = Color(0xFFF43F5E);            // Rose 500
  static const Color accentLight = Color(0xFFFB7185);       // Rose 400
  static const Color accentDark = Color(0xFFBE123C);        // Rose 700
  
  // Background Colors - Ultra clean
  static const Color background = Color(0xFFF8FAFC);        // Slate 50
  static const Color surface = Color(0xFFFFFFFF);           // Pure white
  static const Color cardBackground = Color(0xFFFFFFFF);    // Pure white
  
  // Text Colors - High contrast for readability
  static const Color textPrimary = Color(0xFF0F172A);       // Slate 900
  static const Color textSecondary = Color(0xFF475569);     // Slate 600
  static const Color textLight = Color(0xFF94A3B8);         // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);     // White
  
  // Status Colors - Modern system colors
  static const Color success = Color(0xFF10B981);           // Emerald 500
  static const Color warning = Color(0xFFF59E0B);           // Amber 500
  static const Color error = Color(0xFFEF4444);             // Red 500
  static const Color info = Color(0xFF3B82F6);              // Blue 500
  
  // Divider & Border
  static const Color divider = Color(0xFFE2E8F0);           // Slate 200
  static const Color border = Color(0xFFCBD5E1);            // Slate 300
  
  // Shadow - Softer modern shadow
  static const Color shadowColor = Color(0x0F000000);       // 6% black
  
  // Gradient Colors for modern effects
  static const Color gradientStart = Color(0xFF6366F1);     // Indigo 500
  static const Color gradientEnd = Color(0xFF8B5CF6);       // Violet 500
  
  // Menu Tile Colors (for 3x3 grid) - Modern 2026 palette
  static const Color tileNoteInfo = Color(0xFF10B981);      // Emerald - Fresh green
  static const Color tileMessages = Color(0xFF3B82F6);      // Blue - Classic blue
  static const Color tileSuggestions = Color(0xFFF59E0B);   // Amber - Warm orange
  static const Color tileAbsences = Color(0xFFEF4444);      // Red - Alert red
  static const Color tileResultats = Color(0xFF8B5CF6);     // Violet - Rich purple
  static const Color tileEmploi = Color(0xFF14B8A6);        // Teal - Professional teal
  static const Color tileCourses = Color(0xFF6366F1);       // Indigo - Modern indigo
  static const Color tileMonSolde = Color(0xFF06B6D4);      // Cyan - Bright cyan
  static const Color tileDocuments = Color(0xFFEC4899);     // Pink - Vibrant pink
  static const Color tileMonGroupe = Color(0xFF6366F1);     // Indigo - Group purple
}

class AppSizes {
  // Padding
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;
  
  // Font Sizes
  static const double fontXS = 10.0;
  static const double fontS = 12.0;
  static const double fontM = 14.0;
  static const double fontL = 16.0;
  static const double fontXL = 18.0;
  static const double fontXXL = 20.0;
  static const double fontTitle = 24.0;
  static const double fontHeading = 28.0;
  static const double fontDisplay = 32.0;
  
  // Border Radius - Modern 2026 style (more rounded)
  static const double radiusXS = 6.0;
  static const double radiusS = 10.0;
  static const double radiusM = 14.0;
  static const double radiusL = 18.0;
  static const double radiusXL = 22.0;
  static const double radiusXXL = 28.0;
  static const double radiusCircle = 100.0;
  
  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 40.0;
  static const double iconXXL = 48.0;
  
  // Button Heights
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;
  
  // Card
  static const double cardElevation = 0;                     // Flat design
  static const double cardBorderRadius = 20.0;               // More rounded
  static const double cardShadowBlur = 24.0;                 // Softer shadow
  static const double cardShadowSpread = 0.0;
  
  // Grid Tile - Modern proportions
  static const double gridTileSize = 110.0;
  static const double gridTileIconSize = 28.0;
  static const double gridTileIconContainerSize = 64.0;
  static const double gridSpacing = 14.0;
  
  // Badge
  static const double badgeSize = 18.0;
  static const double badgeFontSize = 10.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textOnPrimary,
      ),
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: const Color(0xFF1E1E1E),
        error: AppColors.error,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: Colors.white.withValues(alpha: 0.87),
        onError: AppColors.textOnPrimary,
      ),
      textTheme: _darkTextTheme,
      appBarTheme: _darkAppBarTheme,
      cardTheme: _darkCardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      bottomNavigationBarTheme: _darkBottomNavigationBarTheme,
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.12),
        thickness: 1,
      ),
    );
  }

  static TextTheme get _textTheme {
    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontDisplay,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontHeading,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontTitle,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontXXL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontL,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontL,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontXS,
        fontWeight: FontWeight.w500,
        color: AppColors.textLight,
      ),
    );
  }

  static TextTheme get _darkTextTheme {
    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontDisplay,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontHeading,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontTitle,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontXXL,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontL,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontL,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontL,
        fontWeight: FontWeight.normal,
        color: Colors.white.withValues(alpha: 0.87),
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        fontWeight: FontWeight.normal,
        color: Colors.white.withValues(alpha: 0.60),
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        fontWeight: FontWeight.normal,
        color: Colors.white.withValues(alpha: 0.60),
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.87),
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.60),
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontXS,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.38),
      ),
    );
  }

  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSizes.iconM,
      ),
    );
  }

  static AppBarTheme get _darkAppBarTheme {
    return AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: AppSizes.iconM,
      ),
    );
  }

  static CardThemeData get _cardTheme {
    return CardThemeData(
      elevation: AppSizes.cardElevation,
      color: AppColors.cardBackground,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
    );
  }

  static CardThemeData get _darkCardTheme {
    return CardThemeData(
      elevation: AppSizes.cardElevation,
      color: const Color(0xFF1E1E1E),
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
    );
  }

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeightM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
          vertical: AppSizes.paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontL,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeightM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
          vertical: AppSizes.paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontL,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontM,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        color: AppColors.textLight,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        color: AppColors.textSecondary,
      ),
      errorStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        color: AppColors.error,
      ),
    );
  }

  static InputDecorationTheme get _darkInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        color: Colors.white.withValues(alpha: 0.38),
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontM,
        color: Colors.white.withValues(alpha: 0.60),
      ),
      errorStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        color: AppColors.error,
      ),
    );
  }

  static BottomNavigationBarThemeData get _bottomNavigationBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  static BottomNavigationBarThemeData get _darkBottomNavigationBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: Colors.white.withValues(alpha: 0.38),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontS,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
