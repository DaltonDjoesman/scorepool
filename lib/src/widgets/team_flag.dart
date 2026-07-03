import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/team_crest_resolve.dart';
import '../utils/team_display.dart';
import '../utils/team_flag_emoji.dart';

/// Team flag: raster crest URL (API PNG or flagcdn), else emoji, else code tile.
class TeamFlag extends StatelessWidget {
  TeamFlag({
    super.key,
    required this.teamId,
    this.crestUrl,
    double? size,
    double width = 36,
    double height = 26,
    this.showCodeFallback = true,
  })  : width = size != null ? size * 1.35 : width,
        height = size ?? height;

  final String teamId;
  final String? crestUrl;
  final double width;
  final double height;
  final bool showCodeFallback;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    if (TeamDisplay.isPlaceholder(teamId)) {
      return _placeholder(colors);
    }

    final crest = displayCrestUrl(teamId: teamId, apiCrest: crestUrl);
    if (crest != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          crest,
          width: width,
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _loadingTile(colors);
          },
          errorBuilder: (context, error, stackTrace) =>
              _emojiOrCode(context, colors),
        ),
      );
    }

    return _emojiOrCode(context, colors);
  }

  Widget _loadingTile(AppColors colors) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.phoneSurfaceHover,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.phoneBorder),
      ),
    );
  }

  Widget _placeholder(AppColors colors) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.phoneSurfaceHover,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.phoneMuted.withValues(alpha: 0.5)),
      ),
      child: Icon(Icons.hourglass_empty, size: height * 0.45, color: colors.phoneMuted),
    );
  }

  Widget _emojiOrCode(BuildContext context, AppColors colors) {
    final emoji = flagEmojiForTeamId(teamId);
    if (emoji != '🏳️' || !showCodeFallback) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: height * 0.85)),
        ),
      );
    }

    final normalized = teamId.trim().toUpperCase();
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.phoneSurfaceHover,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.phoneBorder),
      ),
      child: Text(
        normalized.length >= 3 ? normalized.substring(0, 3) : normalized,
        style: TextStyle(
          fontSize: height * 0.38,
          fontWeight: FontWeight.w700,
          color: colors.phoneMuted,
        ),
      ),
    );
  }
}
