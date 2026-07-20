import 'package:flutter/material.dart';

import '../../models/member.dart';
import '../../repositories/repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

/// Simple participant list for scheduled/live matches (HTML "Participantes do Grupo").
class ParticipantTransparencyList extends StatefulWidget {
  const ParticipantTransparencyList({
    super.key,
    required this.repos,
    required this.groupId,
    required this.matchId,
    required this.memberNames,
    this.currentUid,
  });

  final Repositories repos;
  final String groupId;
  final String matchId;
  final Map<String, String> memberNames;
  final String? currentUid;

  @override
  State<ParticipantTransparencyList> createState() =>
      _ParticipantTransparencyListState();
}

class _ParticipantTransparencyListState
    extends State<ParticipantTransparencyList> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _nameFor(String uid) => widget.memberNames[uid] ?? uid;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return StreamBuilder<List<MemberProfile>>(
      stream: widget.repos.profiles.watchMembers(widget.groupId),
      builder: (context, membersSnap) {
        final members = membersSnap.data ?? [];
        if (membersSnap.connectionState == ConnectionState.waiting &&
            !membersSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<Map<String, bool>>(
          stream: widget.repos.predictions.watchMatchParticipations(
            groupId: widget.groupId,
            matchId: widget.matchId,
          ),
          builder: (context, partSnap) {
            final participations = partSnap.data ?? {};
            final query = _searchController.text.trim().toLowerCase();

            final sorted = [...members]
              ..sort((a, b) => _nameFor(a.uid).compareTo(_nameFor(b.uid)));

            final filtered = sorted.where((m) {
              if (query.isEmpty) return true;
              return _nameFor(m.uid).toLowerCase().contains(query);
            });

            final inPotCount = members.where((m) {
              return participations[m.uid] ?? true;
            }).length;

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Participantes do Grupo',
                        style: AppTextStyles.titleCaps(context),
                      ),
                      Text(
                        '$inPotCount no pote',
                        style: AppTextStyles.sub(context).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar participante...',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...filtered.map((member) {
                    final isMe = member.uid == widget.currentUid;
                    final inPot = participations[member.uid] ?? true;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_nameFor(member.uid)}${isMe ? ' (Você)' : ''}',
                              style: TextStyle(
                                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                                color: isMe ? colors.accent : colors.phoneFg,
                              ),
                            ),
                          ),
                          StatusBadge(
                            label: inPot ? 'No Pote' : 'Fora do Pote',
                            variant: inPot
                                ? StatusBadgeVariant.scheduled
                                : StatusBadgeVariant.ended,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
