import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/team_crest_resolve.dart';
import '../utils/team_display.dart';
import '../utils/team_flag_emoji.dart';

/// Team flag: raster crest URL (API PNG or flagcdn), else emoji, else code tile.
class TeamFlag extends StatelessWidget {
  const TeamFlag({
    super.key,
    required this.teamId,
    this.crestUrl,
    this.size,
    this.width = 36,
    this.height = 26,
    this.showCodeFallback = true,
  });

  final String teamId;
  final String? crestUrl;
  final double? size;
  final double width;
  final double height;
  final bool showCodeFallback;

  double get _w => size != null ? size! * 1.35 : width;
  double get _h => size ?? height;

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
          width: _w,
          height: _h,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          cacheWidth: (_w * 3).round().clamp(48, 240),
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
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        color: colors.phoneSurfaceHover,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.phoneBorder),
      ),
    );
  }

  Widget _placeholder(AppColors colors) {
    return Container(
      width: _w,
      height: _h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.phoneSurfaceHover,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.phoneMuted.withValues(alpha: 0.5)),
      ),
      child: Icon(Icons.hourglass_empty, size: _h * 0.45, color: colors.phoneMuted),
    );
  }

  Widget _emojiOrCode(BuildContext context, AppColors colors) {
    final emoji = flagEmojiForTeamId(teamId);
    if (emoji != '🏳️' || !showCodeFallback) {
      return SizedBox(
        width: _w,
        height: _h,
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: _h * 0.85)),
        ),
      );
    }

    final normalized = teamId.trim().toUpperCase();
    return Container(
      width: _w,
      height: _h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.phoneSurfaceHover,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.phoneBorder),
      ),
      child: Text(
        normalized.length >= 3 ? normalized.substring(0, 3) : normalized,
        style: TextStyle(
          fontSize: _h * 0.38,
          fontWeight: FontWeight.w700,
          color: colors.phoneMuted,
        ),
      ),
    );
  }
}
