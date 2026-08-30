import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color glow;
  final Color glowSecondary;
  final Color cardHighlight;
  final Color subtleText;
  final Color success;
  final Color warning;
  final Color danger;
  final Color waveform;
  final Color waveformGlow;
  final Color deepBackground;

  const AppColorsExtension({
    required this.glow,
    required this.glowSecondary,
    required this.cardHighlight,
    required this.subtleText,
    required this.success,
    required this.warning,
    required this.danger,
    required this.waveform,
    required this.waveformGlow,
    required this.deepBackground,
  });

  @override
  AppColorsExtension copyWith({
    Color? glow,
    Color? glowSecondary,
    Color? cardHighlight,
    Color? subtleText,
    Color? success,
    Color? warning,
    Color? danger,
    Color? waveform,
    Color? waveformGlow,
    Color? deepBackground,
  }) =>
      AppColorsExtension(
        glow: glow ?? this.glow,
        glowSecondary: glowSecondary ?? this.glowSecondary,
        cardHighlight: cardHighlight ?? this.cardHighlight,
        subtleText: subtleText ?? this.subtleText,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        waveform: waveform ?? this.waveform,
        waveformGlow: waveformGlow ?? this.waveformGlow,
        deepBackground: deepBackground ?? this.deepBackground,
      );

  @override
  AppColorsExtension lerp(covariant ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      glow: Color.lerp(glow, other.glow, t)!,
      glowSecondary: Color.lerp(glowSecondary, other.glowSecondary, t)!,
      cardHighlight: Color.lerp(cardHighlight, other.cardHighlight, t)!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      waveform: Color.lerp(waveform, other.waveform, t)!,
      waveformGlow: Color.lerp(waveformGlow, other.waveformGlow, t)!,
      deepBackground: Color.lerp(deepBackground, other.deepBackground, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXl = 24.0;

  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  static const double buttonHeight = 56.0;
  static const double buttonHeightSm = 44.0;

  static const double scannerSize = 260.0;
  static const double traceStripHeight = 56.0;
  static const double lockedTraceHeight = 44.0;

  static const double opacityDisabled = 0.38;
  static const double opacityHint = 0.6;
  static const double opacityOverlay = 0.7;
  static const double opacitySubtle = 0.15;
  static const double opacityFaint = 0.08;

  static const double borderDefault = 1.0;
  static const double borderSelected = 2.0;

  static const _appColors = AppColorsExtension(
    glow: Color(0xFF6C5CE7),
    glowSecondary: Color(0xFF00D2FF),
    cardHighlight: Color(0xFF1E1E32),
    subtleText: Color(0xFF6E6E8A),
    success: Color(0xFF00E676),
    warning: Color(0xFFFFB74D),
    danger: Color(0xFFFF6B6B),
    waveform: Color(0xFF00D2FF),
    waveformGlow: Color(0xFF6C5CE7),
    deepBackground: Color(0xFF060610),
  );

  static final ThemeData darkTheme = _buildTheme(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C5CE7),
      brightness: Brightness.dark,
      surface: const Color(0xFF0C0C18),
      onSurface: const Color(0xFFE8E8F0),
      primary: const Color(0xFF6C5CE7),
      secondary: const Color(0xFF00D2FF),
      tertiary: const Color(0xFF9B59B6),
      error: const Color(0xFFFF6B6B),
    ),
    appColors: _appColors,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
  }) {
    final textTheme = _buildTextTheme(colorScheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: appColors.cardHighlight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: colorScheme.outline.withOpacity(opacitySubtle)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
          foregroundColor: colorScheme.onSurface,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: appColors.cardHighlight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: borderSelected),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: 14),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(opacitySubtle),
        thickness: borderDefault,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: appColors.cardHighlight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: appColors.cardHighlight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      extensions: [appColors],
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
        letterSpacing: 2.0,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: 1.5,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 1.0,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: colorScheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: colorScheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: 1.5,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.7),
        letterSpacing: 1.2,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.5),
        letterSpacing: 1.0,
      ),
    );
  }
}
