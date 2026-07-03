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
