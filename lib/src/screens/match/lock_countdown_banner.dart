import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/match.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/match_lock.dart';

class LockCountdownBanner extends StatefulWidget {
  const LockCountdownBanner({
    super.key,
    required this.match,
    required this.predictionLockMinutes,
  });

  final GroupMatchOverlay match;
  final int predictionLockMinutes;

  @override
  State<LockCountdownBanner> createState() => _LockCountdownBannerState();
}

class _LockCountdownBannerState extends State<LockCountdownBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final remaining = timeUntilLock(
      match: widget.match,
      predictionLockMinutes: widget.predictionLockMinutes,
    );

    final label = remaining == null
        ? 'Palpites trancados'
        : formatTimeUntilLock(remaining);

    final locked = remaining == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: locked
            ? colors.phoneSurfaceHover
            : colors.accentLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: locked
              ? colors.phoneBorder
              : colors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            locked ? Icons.lock_outline : Icons.timer_outlined,
            size: 16,
            color: locked ? colors.phoneMuted : colors.accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.body(context, weight: FontWeight.w600).copyWith(
              color: locked ? colors.phoneMuted : colors.accent,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
