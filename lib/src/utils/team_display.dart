import 'team_metadata.dart';

/// Human-readable labels for tournament team ids (including knockout placeholders).
class TeamDisplay {
  TeamDisplay._();

  static bool isPlaceholder(String teamId) => TeamMetadata.isPlaceholder(teamId);

  static String label(String teamId) => TeamMetadata.label(teamId);
}
