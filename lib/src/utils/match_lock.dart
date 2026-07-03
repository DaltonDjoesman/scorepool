import '../models/match.dart';
import '../models/match_status.dart';

DateTime lockTimeUtc({
  required DateTime matchTimeUtc,
  required int predictionLockMinutes,
}) {
  return matchTimeUtc.subtract(Duration(minutes: predictionLockMinutes));
}

bool isBeforeLock({
  required GroupMatchOverlay match,
  required int predictionLockMinutes,
  DateTime? now,
}) {
  final current = (now ?? DateTime.now()).toUtc();
  if (match.lockedInGroup || match.status != MatchStatus.scheduled) {
    return false;
  }
  return current.isBefore(
    lockTimeUtc(
      matchTimeUtc: match.matchTimeUtc,
      predictionLockMinutes: predictionLockMinutes,
    ),
  );
}

Duration? timeUntilLock({
  required GroupMatchOverlay match,
  required int predictionLockMinutes,
  DateTime? now,
}) {
  if (!isBeforeLock(
    match: match,
    predictionLockMinutes: predictionLockMinutes,
    now: now,
  )) {
    return null;
  }

  final current = (now ?? DateTime.now()).toUtc();
  final lock = lockTimeUtc(
    matchTimeUtc: match.matchTimeUtc,
    predictionLockMinutes: predictionLockMinutes,
  );
  return lock.difference(current);
}

String formatTimeUntilLock(Duration remaining) {
  if (remaining.inSeconds <= 0) return 'Trancado';

  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);
  final seconds = remaining.inSeconds.remainder(60);

  if (hours > 0) return 'Tranca em ${hours}h ${minutes}m';
  if (minutes > 0) return 'Tranca em ${minutes}m';
  return 'Tranca em ${seconds}s';
}
