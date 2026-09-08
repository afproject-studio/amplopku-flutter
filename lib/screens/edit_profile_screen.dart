import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  String _originalName = '';
  String _originalEmail = '';
  bool _loading = true;
  bool _saving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _supportsPassword = true;

  bool get _emailChanged =>
      _emailController.text.trim().toLowerCase() !=
      _originalEmail.trim().toLowerCase();

  bool get _passwordChanged => _newPasswordController.text.isNotEmpty;

  bool get _nameChanged =>
      _nameController.text.trim() != _originalName.trim();

  bool get _requiresReauthentication => _emailChanged || _passwordChanged;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    _originalEmail = user.email?.trim() ?? '';
    _originalName = user.displayName?.trim() ?? '';
    _supportsPassword = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    try {
      final profile = await _firestoreService.getUser(user.uid);
      if (profile.nama.trim().isNotEmpty) {
        _originalName = profile.nama.trim();
      }
    } catch (_) {
      // Nama dari Firebase Auth tetap bisa dipakai apabila Firestore belum siap.
    }

    _nameController.text = _originalName;
    _emailController.text = _originalEmail;

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Nama wajib diisi';
    }

    if (name.length < 2) {
      return 'Nama minimal 2 karakter';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (email.isEmpty) {
      return 'Email wajib diisi';
    }

    if (!emailPattern.hasMatch(email)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (!_requiresReauthentication) {
      return null;
    }

    if (!_supportsPassword) {
      return 'Akun ini tidak menggunakan login email dan password';
    }

    if ((value ?? '').isEmpty) {
      return 'Masukkan password saat ini untuk verifikasi';
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return null;
    }

    if (password.length < 6) {
      return 'Password baru minimal 6 karakter';
    }

    if (password == _currentPasswordController.text) {
      return 'Password baru harus berbeda dari password saat ini';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_passwordChanged) {
      return null;
    }

    if (value != _newPasswordController.text) {
      return 'Konfirmasi password tidak sama';
    }

    return null;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_nameChanged && !_emailChanged && !_passwordChanged) {
      _showMessage('Belum ada perubahan yang disimpan');
      return;
    }

    final user = _authService.currentUser;

    if (user == null) {
      _showMessage('Sesi login telah berakhir', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      if (_requiresReauthentication) {
        await _authService.reauthenticateWithPassword(
          _currentPasswordController.text,
        );
      }

      if (_passwordChanged) {
        await _authService.updatePassword(_newPasswordController.text);
      }

      if (_emailChanged) {
        await _authService.requestEmailChange(
          _emailController.text.trim(),
        );
      }

      if (_nameChanged) {
        final newName = _nameController.text.trim();

        await _authService.updateDisplayName(newName);
        await _firestoreService.updateProfile(
          uid: user.uid,
          nama: newName,
        );
      }

      if (!mounted) return;

      await _showSuccessDialog(
        nameChanged: _nameChanged,
        emailChanged: _emailChanged,
        passwordChanged: _passwordChanged,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showSuccessDialog({
    required bool nameChanged,
    required bool emailChanged,
    required bool passwordChanged,
  }) async {
    final messages = <String>[];

    if (nameChanged) {
      messages.add('Nama profil berhasil diperbarui.');
    }

    if (passwordChanged) {
      messages.add('Password berhasil diperbarui.');
    }

    if (emailChanged) {
      messages.add(
        'Tautan verifikasi telah dikirim ke ${_emailController.text.trim()}. '
        'Email akun berubah setelah tautan tersebut dibuka.',
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 42,
          ),
          title: const Text('Profil berhasil disimpan'),
          content: Text(messages.join('\n\n')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.accentRed : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final horizontalPadding = compact ? 16.0 : 28.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            20,
                            horizontalPadding,
                            40,
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.white24,
                                    child: Icon(
                                      Icons.manage_accounts_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kelola akunmu',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Perbarui nama, email, dan password dengan aman.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SectionCard(
                              title: 'Informasi profil',
                              icon: Icons.person_outline_rounded,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama',
                                    hintText: 'Masukkan nama lengkap',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  validator: _validateName,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  enabled: _supportsPassword,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'nama@email.com',
                                    prefixIcon: const Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                    helperText: _supportsPassword
                                        ? 'Perubahan email memerlukan verifikasi melalui email baru.'
                                        : 'Email tidak dapat diubah karena akun memakai penyedia login lain.',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: _validateEmail,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _SectionCard(
                              title: 'Keamanan akun',
                              icon: Icons.lock_outline_rounded,
                              children: [
                                TextFormField(
                                  controller: _currentPasswordController,
                                  enabled: _supportsPassword,
                                  obscureText: !_showCurrentPassword,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Password saat ini',
                                    helperText:
                                        'Wajib diisi saat mengubah email atau password.',
                                    prefixIcon:
                                        const Icon(Icons.password_rounded),
                                    suffixIcon: IconButton(
                                      tooltip: _showCurrentPassword
                                          ? 'Sembunyikan password'
                                          : 'Tampilkan password',
                                      onPressed: () {
                                        setState(() {
                                          _showCurrentPassword =
                                              !_showCurrentPassword;
                                        });
                                      },
                                      icon: Icon(
                                        _showCurrentPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: _validateCurrentPassword,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _newPasswordController,
                                  enabled: _supportsPassword,
                                  obscureText: !_showNewPassword,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Password baru',
                                    helperText:
                                        'Kosongkan apabila tidak ingin mengganti password.',
                                    prefixIcon:
                                        const Icon(Icons.lock_reset_rounded),
                                    suffixIcon: IconButton(
                                      tooltip: _showNewPassword
                                          ? 'Sembunyikan password'
                                          : 'Tampilkan password',
                                      onPressed: () {
                                        setState(() {
                                          _showNewPassword = !_showNewPassword;
                                        });
                                      },
                                      icon: Icon(
                                        _showNewPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: _validateNewPassword,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  enabled: _supportsPassword,
                                  obscureText: !_showConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _saveProfile(),
                                  decoration: InputDecoration(
                                    labelText: 'Konfirmasi password baru',
                                    prefixIcon:
                                        const Icon(Icons.verified_user_outlined),
                                    suffixIcon: IconButton(
                                      tooltip: _showConfirmPassword
                                          ? 'Sembunyikan password'
                                          : 'Tampilkan password',
                                      onPressed: () {
                                        setState(() {
                                          _showConfirmPassword =
                                              !_showConfirmPassword;
                                        });
                                      },
                                      icon: Icon(
                                        _showConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: _validateConfirmPassword,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Untuk keamanan akun, perubahan email dan password harus dikonfirmasi menggunakan password saat ini.',
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 54,
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _saveProfile,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(
                                  _saving ? 'Menyimpan...' : 'Simpan Perubahan',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 21,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
