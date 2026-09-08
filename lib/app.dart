import 'package:amplopku/core/theme/app_theme.dart';
import 'package:amplopku/providers/theme_provider.dart';
import 'package:amplopku/screens/auth/login_screen.dart';
import 'package:amplopku/screens/manage_envelope_screen.dart';
import 'package:amplopku/screens/navigation/main_navigation_screen.dart';
import 'package:amplopku/screens/setup/setup_envelope_screen.dart';
import 'package:amplopku/screens/setup/setup_income_screen.dart';
import 'package:amplopku/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AmplopKuApp extends StatelessWidget {
  const AmplopKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<ThemeProvider, bool>(
      (provider) => provider.isDarkMode,
    );

    return MaterialApp(
      title: 'AmplopKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Pergantian dibuat langsung agar tidak ada dua tahap subtree
      // tema yang diproses saat halaman berisi banyak widget stateful.
      themeAnimationDuration: Duration.zero,

      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/setup-income': (_) => const SetupIncomeScreen(),
        '/setup-envelope': (_) => const SetupEnvelopeScreen(),
        '/manage-envelope': (_) => const ManageEnvelopeScreen(),
        '/home': (_) => const MainNavigationScreen(),
      },
      initialRoute: '/',
    );
  }
}
