import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import 'create_group_screen.dart';
import 'edit_group_filter_screen.dart';
import '../feed/feed_screen.dart';
import '../ranking/ranking_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  static const routePath = '/group';

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final _groupIdController = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    final auth = appAuth(context);
    final repos = appRepos(context);
    final state = appState(context);
    final user = auth?.user;
    if (user == null || repos == null) return;

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      final groupId = _groupIdController.text.trim();
      await repos.firestore.upsertMemberProfile(
        groupId: groupId,
        uid: user.uid,
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
      );

      state.setCurrentGroupId(groupId);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grupo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecione ou crie um grupo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go(CreateGroupScreen.routePath),
              icon: const Icon(Icons.add),
              label: const Text('Criar grupo'),
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: appState(context),
              builder: (context, _) {
                final groupId = appState(context).currentGroupId;
                if (groupId == null) {
                  return const Text('Grupo atual: —');
                }
                return Row(
                  children: [
                    Expanded(child: Text('Grupo atual: $groupId')),
                    TextButton(
                      onPressed: () => context.go(EditGroupFilterScreen.routePath),
                      child: const Text('Editar filtro'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _groupIdController,
              decoration: const InputDecoration(
                labelText: 'Group ID',
                helperText: 'Por enquanto, digite o ID do grupo para entrar.',
              ),
              enabled: !_joining,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _joining ? null : _joinGroup,
              child: const Text('Entrar no grupo'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Divider(height: 32),
            FilledButton(
              onPressed: () => context.go(FeedScreen.routePath),
              child: const Text('Abrir feed (placeholder)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go(RankingScreen.routePath),
              child: const Text('Ver ranking (placeholder)'),
            ),
          ],
        ),
      ),
    );
  }
}
