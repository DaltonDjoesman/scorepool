import 'package:flutter/material.dart';

import '../../app.dart';
import '../../routing/navigation_helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/alert_box.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'group_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const routePath = '/profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _profileLoadStarted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_profileLoadStarted) return;
    _profileLoadStarted = true;

    final user = appAuth(context)?.user;
    final repos = appRepos(context);
    if (user == null || repos == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final profile = await repos.profiles.fetchUserProfile(user.uid);
      if (!mounted) return;
      setState(() {
        _nameController.text = profile?.displayName.isNotEmpty == true
            ? profile!.displayName
            : (user.displayName ?? '');
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nameController.text = user.displayName ?? '';
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final user = appAuth(context)?.user;
    final repos = appRepos(context);
    if (user == null || repos == null) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final auth = appAuth(context);
    final displayName = _nameController.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await repos.profiles.updateUserProfile(
        uid: user.uid,
        displayName: displayName,
      );
      await auth?.updateDisplayProfile(displayName: displayName);

      if (!mounted) return;
      navigateBack(context, fallback: GroupScreen.routePath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final colors = appColors(context);
    final trimmed = _nameController.text.trim();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PERFIL', style: AppTextStyles.titleCaps(context)),
                          const SizedBox(height: 4),
                          Text(
                            'Editar nome',
                            style: AppTextStyles.displayHeadline(context, size: 24),
                          ),
                        ],
                      ),
                    ),
                    AppButtonOutline(
                      label: 'Voltar',
                      expand: false,
                      onPressed: _saving
                          ? null
                          : () => navigateBack(
                                context,
                                fallback: GroupScreen.routePath,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: colors.phoneBorder,
                    child: trimmed.isNotEmpty
                        ? Text(
                            trimmed[0].toUpperCase(),
                            style: AppTextStyles.displayHeadline(context, size: 28),
                          )
                        : Icon(Icons.person, size: 36, color: colors.phoneMuted),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _nameController,
                  label: 'Nome no bolão',
                  hint: 'Como você aparece no ranking',
                  enabled: !_saving,
                  maxLength: 40,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe um nome.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Este nome aparece no ranking e nas listas de palpites.',
                  style: AppTextStyles.sub(context),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  AlertBox(
                    variant: AlertBoxVariant.danger,
                    child: Text(_error!, style: const TextStyle(fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Salvar nome',
                  onPressed: _saving ? null : _save,
                  isLoading: _saving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
