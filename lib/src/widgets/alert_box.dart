import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AlertBoxVariant { info, danger, warning }

class AlertBox extends StatelessWidget {
  const AlertBox({
    super.key,
    required this.child,
    this.variant = AlertBoxVariant.info,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final AlertBoxVariant variant;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final (bg, border, iconColor) = switch (variant) {
      AlertBoxVariant.info => (
        colors.accentLight.withValues(alpha: 0.35),
        colors.accent.withValues(alpha: 0.25),
        colors.accent,
      ),
      AlertBoxVariant.danger => (
        colors.danger.withValues(alpha: 0.1),
        colors.danger.withValues(alpha: 0.25),
        colors.danger,
      ),
      AlertBoxVariant.warning => (
        colors.goldLight.withValues(alpha: 0.5),
        colors.gold.withValues(alpha: 0.35),
        colors.gold,
      ),
    };

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: colors.phoneFg, fontSize: 13, height: 1.4),
        child: child,
      ),
    );
  }
}
