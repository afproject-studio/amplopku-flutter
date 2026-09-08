import 'dart:async';

import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 900), _checkSession);
  }

  Future<void> _checkSession() async {
    if (!mounted) return;
    final user = AuthService().currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final doc = await FirestoreService().users.doc(user.uid).get();
    final setupCompleted = doc.data()?['setupCompleted'] == true;
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, setupCompleted ? '/home' : '/setup-income');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, Color(0xFF16A34A)]),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(radius: 44, backgroundColor: Colors.white, child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 46)),
          SizedBox(height: 20),
          Text('AmplopKu', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Atur uang dengan metode amplop', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
      ),
    );
  }
}
