import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../match/match_details_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  static const routePath = '/feed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jogos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Feed (placeholder)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Exemplo: BRA x ARG'),
            subtitle: const Text('Detalhes do jogo / palpites / ledger'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(
              MatchDetailsScreen.routePathFor(matchId: 'example-match'),
            ),
          ),
        ],
      ),
    );
  }
}
