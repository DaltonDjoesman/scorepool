import '../models/match.dart';
import '../models/match_status.dart';

/// Pot amount helpers aligned with the HTML prototype `calculatePot`.
class PotCalculator {
  PotCalculator._();

  static int? settledPotCents(GroupMatchOverlay match) {
    if (match.totalPotCents != null) return match.totalPotCents;
    final base = match.basePotCents;
    if (base == null && match.accumulatedFromPreviousCents == 0) return null;
    return (base ?? 0) + match.accumulatedFromPreviousCents;
  }

  static int estimatePotCents({
    required int entryFeeCents,
    required int inPotParticipantCount,
    required int accumulatedFromPreviousCents,
  }) {
    return entryFeeCents * inPotParticipantCount + accumulatedFromPreviousCents;
  }

  /// Count members in the pot; missing participation docs default to in-pot.
  static int countInPotParticipants({
    required int memberCount,
    required Map<String, bool> participationByUid,
  }) {
    if (memberCount == 0) return 0;
    var inPot = 0;
    for (final entry in participationByUid.entries) {
      if (entry.value) inPot++;
    }
    // Members without an explicit doc default to in-pot.
    final withoutDoc = memberCount - participationByUid.length;
    return inPot + withoutDoc;
  }

  static int displayPotCents({
    required GroupMatchOverlay match,
    required int entryFeeCents,
    required int inPotParticipantCount,
  }) {
    if (match.status == MatchStatus.finished) {
      return settledPotCents(match) ??
          estimatePotCents(
            entryFeeCents: entryFeeCents,
            inPotParticipantCount: inPotParticipantCount,
            accumulatedFromPreviousCents: match.accumulatedFromPreviousCents,
          );
    }
    return estimatePotCents(
      entryFeeCents: entryFeeCents,
      inPotParticipantCount: inPotParticipantCount,
      accumulatedFromPreviousCents: match.accumulatedFromPreviousCents,
    );
  }

  static String potSubtitle({
    required GroupMatchOverlay match,
    required bool hasWinners,
  }) {
    if (hasWinners) return 'Pote Acumulado Distribuído';
    if (match.status == MatchStatus.finished) {
      return 'Sem vencedores — pote acumulado ❄️';
    }
    return 'Pote acumulado estimado';
  }
}
