import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/providers/theme_provider.dart';
import 'package:amplopku/screens/calendar_screen.dart';
import 'package:amplopku/screens/edit_profile_screen.dart';
import 'package:amplopku/screens/export_data_screen.dart';
import 'package:amplopku/screens/manage_envelope_screen.dart';
import 'package:amplopku/screens/saving_target_screen.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _lastSyncedEmail;

  Future<void> _logout() async {
    await AuthService().logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
    );
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );

    if (updated != true) return;

    await AuthService().reloadCurrentUser();

    if (mounted) {
      setState(() {});
    }
  }

  void _syncVerifiedEmail({
    required String uid,
    required String authEmail,
    required String storedEmail,
  }) {
    final normalizedAuthEmail = authEmail.trim().toLowerCase();
    final normalizedStoredEmail = storedEmail.trim().toLowerCase();

    if (normalizedAuthEmail.isEmpty ||
        normalizedAuthEmail == normalizedStoredEmail ||
        _lastSyncedEmail == normalizedAuthEmail) {
      return;
    }

    _lastSyncedEmail = normalizedAuthEmail;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await FirestoreService().updateUserEmail(
          uid: uid,
          email: authEmail,
        );
      } catch (_) {
        _lastSyncedEmail = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().userStream(user.uid),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? <String, dynamic>{};
            final storedName = (data['nama'] ?? '').toString().trim();
            final storedEmail = (data['email'] ?? '').toString().trim();
            final authEmail = user.email?.trim() ?? '';

            final name = storedName.isNotEmpty
                ? storedName
                : (user.displayName?.trim().isNotEmpty ?? false)
                    ? user.displayName!.trim()
                    : authEmail.isNotEmpty
                        ? authEmail.split('@').first
                        : 'Pengguna';

            final email = authEmail.isNotEmpty
                ? authEmail
                : storedEmail.isNotEmpty
                    ? storedEmail
                    : '-';

            if (authEmail.isNotEmpty) {
              _syncVerifiedEmail(
                uid: user.uid,
                authEmail: authEmail,
                storedEmail: storedEmail,
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final horizontalPadding = compact ? 16.0 : 30.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        24,
                        horizontalPadding,
                        40,
                      ),
                      children: [
                        Container(
                          padding: EdgeInsets.all(compact ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 34,
                                backgroundColor: AppColors.primary,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 19,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Edit profil',
                                onPressed: _openEditProfile,
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _menu(
                          Icons.manage_accounts_outlined,
                          'Edit Profil',
                          _openEditProfile,
                        ),
                        _menu(
                          Icons.mail_outline,
                          'Kelola Amplop',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ManageEnvelopeScreen(),
                              ),
                            );
                          },
                        ),
                        _menu(
                          Icons.calendar_month,
                          'Kalender Transaksi',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CalendarScreen(),
                              ),
                            );
                          },
                        ),
                        _menu(
                          Icons.track_changes,
                          'Target Tabungan',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SavingTargetScreen(),
                              ),
                            );
                          },
                        ),
                        _menu(
                          Icons.file_download_outlined,
                          'Export Data',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExportDataScreen(),
                              ),
                            );
                          },
                        ),
                        Selector<ThemeProvider, bool>(
                          selector: (_, provider) =>
                              provider.isDarkMode,
                          builder: (context, isDarkMode, _) {
                            return SwitchListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              secondary:
                                  const Icon(Icons.dark_mode_outlined),
                              title: const Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              value: isDarkMode,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                context
                                    .read<ThemeProvider>()
                                    .toggleTheme(value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: AppColors.accentRed,
                            ),
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _menu(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(.10),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
