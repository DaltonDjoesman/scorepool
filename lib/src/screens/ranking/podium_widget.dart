import 'package:flutter/material.dart';

import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Top-3 podium matching the HTML prototype layout (2nd | 1st | 3rd).
class PodiumWidget extends StatelessWidget {
  const PodiumWidget({super.key, required this.members});

  final List<MemberProfile> members;

  @override
  Widget build(BuildContext context) {
    if (members.length < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: SizedBox(
        height: 168,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _PodiumBlock(rank: 2, member: members[1])),
            const SizedBox(width: 12),
            Expanded(child: _PodiumBlock(rank: 1, member: members[0])),
            const SizedBox(width: 12),
            Expanded(child: _PodiumBlock(rank: 3, member: members[2])),
          ],
        ),
      ),
    );
  }
}

class _PodiumBlock extends StatelessWidget {
  const _PodiumBlock({required this.rank, required this.member});

  final int rank;
  final MemberProfile member;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final name = member.displayName.isNotEmpty ? member.displayName : member.uid;
    final height = switch (rank) {
      1 => 120.0,
      2 => 88.0,
      _ => 68.0,
    };
    final borderColor = rank == 1 ? colors.gold : colors.phoneBorder;

    return SizedBox(
      height: 168,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: rank == 1 ? 0 : 12,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rank == 1)
                  const Text('👑', style: TextStyle(fontSize: 22)),
                if (rank == 1) const SizedBox(height: 4),
                _PodiumAvatar(rank: rank, member: member, highlight: rank == 1),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: colors.phoneSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  top: BorderSide(color: borderColor, width: rank == 1 ? 2 : 1),
                  left: BorderSide(color: borderColor, width: rank == 1 ? 2 : 1),
                  right: BorderSide(color: borderColor, width: rank == 1 ? 2 : 1),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$rankº',
                    style: AppTextStyles.displayHeadline(context, size: 22).copyWith(
                      fontSize: rank == 1 ? 24 : (rank == 2 ? 20 : 18),
                      color: rank == 1 ? colors.gold : colors.phoneMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      context,
                      weight: rank == 1 ? FontWeight.w700 : FontWeight.w600,
                    ).copyWith(fontSize: rank == 3 ? 11 : 12),
                  ),
                  Text(
                    '${member.perfectScoresCount} acertos',
                    style: AppTextStyles.sub(context).copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumAvatar extends StatelessWidget {
  const _PodiumAvatar({
    required this.rank,
    required this.member,
    this.highlight = false,
  });

  final int rank;
  final MemberProfile member;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final initial = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : '$rank';

    if (member.photoUrl != null && member.photoUrl!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: highlight
              ? Border.all(color: colors.gold, width: 2)
              : null,
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(member.photoUrl!),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: highlight ? Border.all(color: colors.gold, width: 2) : null,
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: colors.phoneSurfaceHover,
        child: Text(
          initial,
          style: TextStyle(fontWeight: FontWeight.w700, color: colors.phoneFg),
        ),
      ),
    );
  }
}
