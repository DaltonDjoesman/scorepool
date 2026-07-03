import 'package:flutter/material.dart';

import '../models/match_status.dart';
import 'status_badge.dart';

class MatchStatusBadge extends StatelessWidget {
  const MatchStatusBadge({
    super.key,
    required this.status,
    this.archived = false,
  });

  final MatchStatus status;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    if (archived) {
      return const StatusBadge(
        label: 'Arquivado',
        variant: StatusBadgeVariant.ended,
      );
    }

    return switch (status) {
      MatchStatus.scheduled => const StatusBadge(
        label: 'Agendado',
        variant: StatusBadgeVariant.scheduled,
      ),
      MatchStatus.live => const StatusBadge(
        label: 'Ao Vivo',
        variant: StatusBadgeVariant.live,
      ),
      MatchStatus.finished => const StatusBadge(
        label: 'Encerrado',
        variant: StatusBadgeVariant.ended,
      ),
    };
  }
}
