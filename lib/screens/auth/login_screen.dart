import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:amplopku/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email dan password wajib diisi')));
      return;
    }

    setState(() => isLoading = true);
    try {
      final credential = await AuthService().login(email: emailController.text.trim(), password: passwordController.text.trim());
      final uid = credential.user!.uid;
      final userDoc = await FirestoreService().users.doc(uid).get();
      final setupCompleted = userDoc.data()?['setupCompleted'] == true;
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, setupCompleted ? '/home' : '/setup-income', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi email terlebih dahulu')));
      return;
    }
    try {
      await AuthService().sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link reset password sudah dikirim ke email')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 26),
            Text('Selamat datang 👋', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text('Masuk dengan akun Firebase untuk melihat ringkasan amplop dan transaksi keuanganmu.', style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 32),
            CustomTextField(hintText: 'Email', prefixIcon: Icons.email_outlined, controller: emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            CustomTextField(hintText: 'Password', prefixIcon: Icons.lock_outline, controller: passwordController, isPassword: true),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _resetPassword, child: const Text('Lupa password?'))),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(onPressed: isLoading ? null : _login, child: Text(isLoading ? 'Masuk...' : 'Masuk')),
            ),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Belum punya akun? ', style: TextStyle(color: AppColors.textGrey)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Daftar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
