import '../models/match.dart';
import '../models/match_status.dart';

extension GroupMatchOverlayScore on GroupMatchOverlay {
  bool get hasScoreline =>
      this.homeScore != null &&
      this.awayScore != null &&
      (status == MatchStatus.finished || status == MatchStatus.live);

  String get scorelineLabel => '${this.homeScore} x ${this.awayScore}';
}

String matchCenterDisplay({
  required GroupMatchOverlay match,
  required bool showPredictionInputs,
}) {
  if (showPredictionInputs) return '';
  if (match.hasScoreline) return match.scorelineLabel;
  return '— x —';
}
