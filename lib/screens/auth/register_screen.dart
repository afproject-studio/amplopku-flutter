import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:amplopku/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if ([nameController, emailController, passwordController, confirmController].any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua field wajib diisi')));
      return;
    }
    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak sama')));
      return;
    }

    setState(() => isLoading = true);
    try {
      final credential = await AuthService().register(email: emailController.text.trim(), password: passwordController.text.trim());
      final user = credential.user!;
      await FirestoreService().createUser(uid: user.uid, nama: nameController.text.trim(), email: emailController.text.trim());
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/setup-income', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Buat akun baru', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Akun akan dibuat di Firebase Authentication, lalu profil user disimpan ke Cloud Firestore.', style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 24),
            CustomTextField(hintText: 'Nama lengkap', prefixIcon: Icons.person_outline, controller: nameController),
            const SizedBox(height: 14),
            CustomTextField(hintText: 'Email', prefixIcon: Icons.email_outlined, controller: emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            CustomTextField(hintText: 'Password', prefixIcon: Icons.lock_outline, controller: passwordController, isPassword: true),
            const SizedBox(height: 14),
            CustomTextField(hintText: 'Konfirmasi password', prefixIcon: Icons.lock_reset, controller: confirmController, isPassword: true),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(onPressed: isLoading ? null : _register, child: Text(isLoading ? 'Mendaftarkan...' : 'Daftar dan Lanjut')),
            ),
          ]),
        ),
      ),
    );
  }
}
