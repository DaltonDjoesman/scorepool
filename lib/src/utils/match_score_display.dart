import '../models/match.dart';
import '../models/match_status.dart';

extension GroupMatchOverlayScore on GroupMatchOverlay {
  bool get hasScoreline =>
      homeScore != null &&
      awayScore != null &&
      (status == MatchStatus.finished || status == MatchStatus.live);

  String get scorelineLabel => '$homeScore x $awayScore';
}

String matchCenterDisplay({
  required GroupMatchOverlay match,
  required bool showPredictionInputs,
}) {
  if (showPredictionInputs) return '';
  if (match.hasScoreline) return match.scorelineLabel;
  return '— x —';
}
