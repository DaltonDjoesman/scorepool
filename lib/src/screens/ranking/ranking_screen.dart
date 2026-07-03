import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/member.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  static const routePath = '/ranking';

  @override
  Widget build(BuildContext context) {
    final groupId = appState(context).currentGroupId;
    final repos = appRepos(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: groupId == null || repos == null
            ? Text(
                'Selecione um grupo primeiro (tela Grupo).',
                style: Theme.of(context).textTheme.bodyLarge,
              )
            : StreamBuilder<List<MemberProfile>>(
                stream: repos.firestore.watchMembers(groupId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final members = snapshot.data!;
                  if (members.isEmpty) {
                    return const Center(child: Text('Nenhum membro no grupo.'));
                  }

                  final sorted = [...members]
                    ..sort((a, b) {
                      final score = b.perfectScoresCount.compareTo(
                        a.perfectScoresCount,
                      );
                      if (score != 0) return score;
                      final name = a.displayName.compareTo(b.displayName);
                      if (name != 0) return name;
                      return a.uid.compareTo(b.uid);
                    });

                  return ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _MemberTile(rank: index + 1, member: sorted[index]);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.rank, required this.member});

  final int rank;
  final MemberProfile member;

  @override
  Widget build(BuildContext context) {
    final display = member.displayName.isNotEmpty
        ? member.displayName
        : member.uid;

    final avatar = member.photoUrl == null || member.photoUrl!.isEmpty
        ? CircleAvatar(child: Text('$rank'))
        : CircleAvatar(backgroundImage: NetworkImage(member.photoUrl!));

    return ListTile(
      leading: avatar,
      title: Text(display),
      subtitle: Text('Placares exatos: ${member.perfectScoresCount}'),
      trailing: Text('#$rank'),
    );
  }
}
