import 'package:flutter/material.dart';

class MatchDetailsScreen extends StatelessWidget {
  const MatchDetailsScreen({super.key, required this.matchId});

  static const routePath = '/match/:matchId';

  static String routePathFor({required String matchId}) => '/match/$matchId';

  final String matchId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Jogo: $matchId',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text('Aqui entram: palpite, opt-out, winners, ledger.'),
          ],
        ),
      ),
    );
  }
}
