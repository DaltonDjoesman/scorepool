import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/match.dart';
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
    final remaining = timeUntilLock(
      match: widget.match,
      predictionLockMinutes: widget.predictionLockMinutes,
    );

    final label = remaining == null
        ? 'Palpites trancados'
        : formatTimeUntilLock(remaining);

    final colorScheme = Theme.of(context).colorScheme;
    final locked = remaining == null;

    return Card(
      color: locked ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              locked ? Icons.lock_outline : Icons.timer_outlined,
              color: locked ? colorScheme.outline : colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: locked
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
