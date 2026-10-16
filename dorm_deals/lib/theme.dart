import 'package:flutter/material.dart';

// One warm neutral family plus a single forest green accent pulled from the logo.
class AppColors {
  static const paper = Color(0xFFF5F3EE);
  static const surface = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFEDEAE3);
  static const hairline = Color(0xFFE2DED4);
  static const ink = Color(0xFF18201C);
  static const inkMuted = Color(0xFF5D655F);
  static const inkFaint = Color(0xFF8E948F);
  static const accent = Color(0xFF1E5B45);
  static const accentPressed = Color(0xFF164634);
  static const accentSoft = Color(0xFFDDE9E1);
  static const danger = Color(0xFFA5402D);
  static const dangerSoft = Color(0xFFF6E3DE);
}

const displayFont = 'BricolageGrotesque';
const bodyFont = 'Geist';

// Tinted shadow so cards lift off the paper instead of sitting in grey smudge.
const softShadow = [
  BoxShadow(
    color: Color(0x141E3A2E),
    blurRadius: 24,
    offset: Offset(0, 8),
    spreadRadius: -6,
  ),
];

ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        surface: AppColors.paper,
      ).copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.accentSoft,
        onPrimaryContainer: AppColors.accentPressed,
        secondaryContainer: AppColors.accentSoft,
        onSecondaryContainer: AppColors.accentPressed,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.inkMuted,
        surfaceContainerLowest: AppColors.surface,
        surfaceContainerLow: AppColors.surface,
        surfaceContainer: AppColors.surface,
        surfaceContainerHigh: AppColors.paper,
        surfaceContainerHighest: AppColors.sunken,
        outline: AppColors.inkFaint,
        outlineVariant: AppColors.hairline,
        error: AppColors.danger,
        errorContainer: AppColors.dangerSoft,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: bodyFont,
  );

  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  TextStyle? display(TextStyle? style, double size, double tracking) {
    return style?.copyWith(
      fontFamily: displayFont,
      fontWeight: FontWeight.w700,
      fontSize: size,
      letterSpacing: tracking,
      height: 1.1,
    );
  }

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  const buttonText = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w600,
    fontSize: 15,
  );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: text.copyWith(
      displaySmall: display(text.displaySmall, 34, -1.0),
      headlineMedium: display(text.headlineMedium, 28, -0.8),
      headlineSmall: display(text.headlineSmall, 24, -0.6),
      titleLarge: text.titleLarge?.copyWith(
        fontFamily: displayFont,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
      bodySmall: text.bodySmall?.copyWith(color: AppColors.inkMuted),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: TextStyle(
        fontFamily: displayFont,
        fontWeight: FontWeight.w700,
        fontSize: 21,
        letterSpacing: -0.5,
        color: AppColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.hairline),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.sunken,
            disabledForegroundColor: AppColors.inkFaint,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: buttonShape,
            textStyle: buttonText,
          ).copyWith(
            overlayColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: 0.08),
            ),
          ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(0, 44),
        side: const BorderSide(color: AppColors.hairline),
        shape: buttonShape,
        textStyle: buttonText.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.inkMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.inkFaint),
      labelStyle: const TextStyle(color: AppColors.inkMuted),
      floatingLabelStyle: const TextStyle(color: AppColors.accent),
      prefixIconColor: AppColors.inkFaint,
      suffixIconColor: AppColors.inkFaint,
      border: inputBorder(AppColors.hairline),
      enabledBorder: inputBorder(AppColors.hairline),
      focusedBorder: inputBorder(AppColors.accent, 1.5),
      errorBorder: inputBorder(AppColors.danger),
      focusedErrorBorder: inputBorder(AppColors.danger, 1.5),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.ink,
      disabledColor: AppColors.sunken,
      side: const BorderSide(color: AppColors.hairline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(
        fontFamily: bodyFont,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: AppColors.ink,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: bodyFont,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: Colors.white,
      ),
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(
        fontFamily: displayFont,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.5,
        color: AppColors.ink,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: bodyFont,
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}
