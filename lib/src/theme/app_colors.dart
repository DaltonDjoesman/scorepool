import 'package:flutter/material.dart';

/// Semantic colors aligned with `worldcup-bet-tracker.html` (hue ~142).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.accentLight,
    required this.gold,
    required this.goldLight,
    required this.danger,
    required this.success,
    required this.phoneBg,
    required this.phoneSurface,
    required this.phoneSurfaceHover,
    required this.phoneFg,
    required this.phoneMuted,
    required this.phoneBorder,
    required this.phoneInputBg,
  });

  final Color accent;
  final Color accentLight;
  final Color gold;
  final Color goldLight;
  final Color danger;
  final Color success;
  final Color phoneBg;
  final Color phoneSurface;
  final Color phoneSurfaceHover;
  final Color phoneFg;
  final Color phoneMuted;
  final Color phoneBorder;
  final Color phoneInputBg;

  static const dark = AppColors(
    accent: Color(0xFF3DB87A),
    accentLight: Color(0xFF1A3D2B),
    gold: Color(0xFFEAB308),
    goldLight: Color(0xFF3D3414),
    danger: Color(0xFFEF4444),
    success: Color(0xFF3DB87A),
    phoneBg: Color(0xFF0C110D),
    phoneSurface: Color(0xFF141B16),
    phoneSurfaceHover: Color(0xFF1B261F),
    phoneFg: Color(0xFFECF3EE),
    phoneMuted: Color(0xFF809689),
    phoneBorder: Color(0xFF1E2A21),
    phoneInputBg: Color(0xFF070A08),
  );

  @override
  AppColors copyWith({
    Color? accent,
    Color? accentLight,
    Color? gold,
    Color? goldLight,
    Color? danger,
    Color? success,
    Color? phoneBg,
    Color? phoneSurface,
    Color? phoneSurfaceHover,
    Color? phoneFg,
    Color? phoneMuted,
    Color? phoneBorder,
    Color? phoneInputBg,
  }) {
    return AppColors(
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      gold: gold ?? this.gold,
      goldLight: goldLight ?? this.goldLight,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      phoneBg: phoneBg ?? this.phoneBg,
      phoneSurface: phoneSurface ?? this.phoneSurface,
      phoneSurfaceHover: phoneSurfaceHover ?? this.phoneSurfaceHover,
      phoneFg: phoneFg ?? this.phoneFg,
      phoneMuted: phoneMuted ?? this.phoneMuted,
      phoneBorder: phoneBorder ?? this.phoneBorder,
      phoneInputBg: phoneInputBg ?? this.phoneInputBg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldLight: Color.lerp(goldLight, other.goldLight, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      phoneBg: Color.lerp(phoneBg, other.phoneBg, t)!,
      phoneSurface: Color.lerp(phoneSurface, other.phoneSurface, t)!,
      phoneSurfaceHover:
          Color.lerp(phoneSurfaceHover, other.phoneSurfaceHover, t)!,
      phoneFg: Color.lerp(phoneFg, other.phoneFg, t)!,
      phoneMuted: Color.lerp(phoneMuted, other.phoneMuted, t)!,
      phoneBorder: Color.lerp(phoneBorder, other.phoneBorder, t)!,
      phoneInputBg: Color.lerp(phoneInputBg, other.phoneInputBg, t)!,
    );
  }
}

AppColors appColors(BuildContext context) =>
    Theme.of(context).extension<AppColors>() ?? AppColors.dark;
