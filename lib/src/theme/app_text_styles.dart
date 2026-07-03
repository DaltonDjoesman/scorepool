import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayHeadline(BuildContext context, {double? size}) {
    final colors = appColors(context);
    return GoogleFonts.outfit(
      fontSize: size ?? 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02,
      color: colors.phoneFg,
      height: 1.15,
    );
  }

  static TextStyle titleCaps(BuildContext context) {
    final colors = appColors(context);
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.08,
      color: colors.phoneMuted,
    );
  }

  static TextStyle sub(BuildContext context) {
    final colors = appColors(context);
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: colors.phoneMuted,
      height: 1.45,
    );
  }

  static TextStyle body(BuildContext context, {FontWeight weight = FontWeight.w400}) {
    final colors = appColors(context);
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: weight,
      color: colors.phoneFg,
      height: 1.45,
    );
  }

  static TextStyle label(BuildContext context) {
    final colors = appColors(context);
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.08,
      color: colors.phoneMuted,
    );
  }
}
