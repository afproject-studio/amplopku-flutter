import 'package:amplopku/screens/dashboard/dashboard_screen.dart';
import 'package:amplopku/screens/manage_envelope_screen.dart';
import 'package:amplopku/screens/profil_screen.dart';
import 'package:amplopku/screens/report_screen.dart';
import 'package:amplopku/screens/transactions/add_transaction_screen.dart';
import 'package:flutter/material.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _changePage(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });
  }

  void _handleTransactionSaved() {
    if (!mounted) return;

    setState(() {
      _currentIndex = 0;
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
          onOpenReport: () => _changePage(3),
        );
      case 1:
        return const ManageEnvelopeScreen();
      case 2:
        return AddTransactionScreen(
          onTransactionSaved: _handleTransactionSaved,
        );
      case 3:
        return const ReportScreen();
      case 4:
        return const ProfileScreen();
      default:
        return DashboardScreen(
          onOpenReport: () => _changePage(3),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // Hanya halaman aktif yang dimasukkan ke widget tree.
      // Ini mencegah beberapa Form/GlobalKey dari halaman tersembunyi
      // ikut hidup bersamaan ketika tema aplikasi berubah.
      body: KeyedSubtree(
        key: ValueKey<int>(_currentIndex),
        child: _buildCurrentPage(),
      ),

      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _currentIndex,
        onSelected: _changePage,
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 420;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          height: compact ? 66 : 74,
          backgroundColor: colors.surface,
          indicatorColor: colors.primaryContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelBehavior: compact
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Amplop',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(Icons.add_circle_rounded),
              label: 'Tambah',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
