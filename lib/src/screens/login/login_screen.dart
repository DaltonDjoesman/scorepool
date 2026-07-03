import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import '../../config/app_config.dart';
import '../group/group_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.config, required this.auth});

  static const routePath = '/login';

  final AppConfig config;
  final AuthController? auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCreateAccount = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.config.firebaseEnabled) {
      if (!mounted) return;
      context.go(GroupScreen.routePath);
      return;
    }

    final auth = widget.auth;
    if (auth == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isCreateAccount) {
        await auth.createAccountWithEmailPassword(
          email: email,
          password: password,
        );
      } else {
        await auth.signInWithEmailPassword(email: email, password: password);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signInGoogle() async {
    final auth = widget.auth;
    if (auth == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signInApple() async {
    final auth = widget.auth;
    if (auth == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await auth.signInWithApple();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final user = auth?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'World Cup Bet Tracker',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              widget.config.firebaseEnabled
                  ? 'Firebase habilitado (modo real).'
                  : 'Firebase desabilitado (modo protótipo UI).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (widget.config.firebaseEnabled && user != null) ...[
              Text('Logado como: ${user.email ?? user.uid}'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _submitting ? null : () async => auth?.signOut(),
                child: const Text('Sair'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submitting
                    ? null
                    : () => context.go(GroupScreen.routePath),
                child: const Text('Continuar'),
              ),
              const Spacer(),
            ] else ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                enabled: !_submitting,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                enabled: !_submitting,
              ),
              const SizedBox(height: 12),
              if (widget.config.firebaseEnabled)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Criar conta'),
                  value: _isCreateAccount,
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _isCreateAccount = v),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              if (widget.config.firebaseEnabled) ...[
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _signInGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar com Google'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _signInApple,
                  icon: const Icon(Icons.apple),
                  label: const Text('Entrar com Apple (iOS)'),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(
                  widget.config.firebaseEnabled
                      ? (_isCreateAccount ? 'Criar e entrar' : 'Entrar')
                      : 'Continuar',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
