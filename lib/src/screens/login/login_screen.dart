import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/alert_box.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  static const routePath = '/login';

  final AuthController? auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isCreateAccount = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = widget.auth;
    if (auth == null) return;

    if (_isCreateAccount &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }

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
      setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendlyAuthError(Object error) {
    final message = error.toString();
    if (message.contains('CONFIGURATION_NOT_FOUND') ||
        message.contains('OPERATION_NOT_ALLOWED')) {
      return 'Firebase Auth (Email/Password) não está activo neste projecto. '
          'No Console Firebase → Authentication → Sign-in method, '
          'habilite Email/Password.';
    }
    if (message.contains('invalid-email')) {
      return 'Email inválido. Use um endereço como nome@exemplo.com';
    }
    if (message.contains('weak-password')) {
      return 'Senha muito fraca. Use pelo menos 6 caracteres.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final user = auth?.user;

    if (user != null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colors = appColors(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            24,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colors.accentLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.accent),
                      ),
                      child: Icon(Icons.sports_soccer, color: colors.accent, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scorepool',
                      style: AppTextStyles.displayHeadline(context),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                AlertBox(
                  variant: AlertBoxVariant.danger,
                  child: Text(_error!),
                ),
                const SizedBox(height: 16),
              ],
              _LoginForm(
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                isCreateAccount: _isCreateAccount,
                submitting: _submitting,
                onToggleRegister: () => setState(() {
                  _isCreateAccount = !_isCreateAccount;
                  _error = null;
                }),
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isCreateAccount,
    required this.submitting,
    required this.onToggleRegister,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isCreateAccount;
  final bool submitting;
  final VoidCallback onToggleRegister;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: emailController,
          label: 'ENDEREÇO DE E-MAIL',
          hint: 'seu.nome@exemplo.com',
          keyboardType: TextInputType.emailAddress,
          enabled: !submitting,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: passwordController,
          label: 'SENHA DE ACESSO',
          hint: 'Mínimo de 6 caracteres',
          obscureText: true,
          enabled: !submitting,
        ),
        if (isCreateAccount) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: confirmPasswordController,
            label: 'CONFIRMAR SENHA',
            hint: 'Repita a senha informada',
            obscureText: true,
            enabled: !submitting,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isCreateAccount ? 'Já possui conta?' : 'Novo por aqui?',
              style: AppTextStyles.sub(context),
            ),
            TextButton(
              onPressed: submitting ? null : onToggleRegister,
              child: Text(isCreateAccount ? 'Entrar' : 'Criar conta'),
            ),
          ],
        ),
        AppButton(
          label: isCreateAccount ? 'Cadastrar conta' : 'Entrar',
          onPressed: submitting ? null : onSubmit,
          isLoading: submitting,
        ),
        const SizedBox(height: 8),
        Text(
          'O bolão transparente jogo a jogo com sua família e amigos.',
          style: AppTextStyles.sub(context).copyWith(color: colors.phoneMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
