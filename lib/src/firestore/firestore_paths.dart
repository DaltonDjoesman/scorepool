class FirestorePaths {
  static const groups = 'groups';
  static const tournaments = 'tournaments';
  static const users = 'users';

  static String user(String uid) => '$users/$uid';

  static String group(String groupId) => '$groups/$groupId';
  static String groupMembers(String groupId) => '${group(groupId)}/members';
  static String groupMember(String groupId, String uid) =>
      '${groupMembers(groupId)}/$uid';

  static String groupMatches(String groupId) => '${group(groupId)}/matches';
  static String groupMatch(String groupId, String matchId) =>
      '${groupMatches(groupId)}/$matchId';

  static String groupRoundParticipants(String groupId) =>
      '${group(groupId)}/roundParticipants';
  static String groupRoundUsers(String groupId, String matchId) =>
      '${groupRoundParticipants(groupId)}/$matchId/users';
  static String groupRoundUser(String groupId, String matchId, String uid) =>
      '${groupRoundUsers(groupId, matchId)}/$uid';

  static String groupPredictions(String groupId) =>
      '${group(groupId)}/predictions';
  static String groupPrediction(String groupId, String predictionId) =>
      '${groupPredictions(groupId)}/$predictionId';

  static String groupDebts(String groupId) => '${group(groupId)}/debts';
  static String groupDebtMatch(String groupId, String matchId) =>
      '${groupDebts(groupId)}/$matchId';
  static String groupDebtItems(String groupId, String matchId) =>
      '${groupDebtMatch(groupId, matchId)}/items';
  static String groupDebtItem(
    String groupId,
    String matchId,
    String debtItemId,
  ) => '${groupDebtItems(groupId, matchId)}/$debtItemId';

  static String tournamentMatches(String tournamentId) =>
      '$tournaments/$tournamentId/matches';
  static String tournamentMatch(String tournamentId, String matchId) =>
      '${tournamentMatches(tournamentId)}/$matchId';

  static String tournamentTeams(String tournamentId) =>
      '$tournaments/$tournamentId/teams';
  static String tournamentTeam(String tournamentId, String teamId) =>
      '${tournamentTeams(tournamentId)}/$teamId';
}
