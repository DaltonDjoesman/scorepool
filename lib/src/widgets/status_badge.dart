import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusBadgeVariant { paid, unpaid, winner, scheduled, live, ended, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.variant,
    this.icon,
  });

  final String label;
  final StatusBadgeVariant variant;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final (bg, fg, border) = switch (variant) {
      StatusBadgeVariant.paid => (
        colors.accentLight.withValues(alpha: 0.5),
        colors.success,
        colors.success.withValues(alpha: 0.3),
      ),
      StatusBadgeVariant.unpaid => (
        colors.danger.withValues(alpha: 0.12),
        colors.danger,
        colors.danger.withValues(alpha: 0.25),
      ),
      StatusBadgeVariant.winner => (
        colors.goldLight,
        colors.gold,
        colors.gold.withValues(alpha: 0.4),
      ),
      StatusBadgeVariant.scheduled => (
        colors.accentLight,
        colors.accent,
        colors.accent.withValues(alpha: 0.25),
      ),
      StatusBadgeVariant.live => (
        colors.danger.withValues(alpha: 0.15),
        colors.danger,
        colors.danger.withValues(alpha: 0.3),
      ),
      StatusBadgeVariant.ended => (
        colors.phoneSurfaceHover,
        colors.phoneMuted,
        colors.phoneBorder,
      ),
      StatusBadgeVariant.info => (
        colors.accentLight.withValues(alpha: 0.35),
        colors.accent,
        colors.accent.withValues(alpha: 0.2),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.02,
            ),
          ),
        ],
      ),
    );
  }
}
