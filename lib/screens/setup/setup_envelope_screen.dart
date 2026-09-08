import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/core/utils/currency.dart';
import 'package:amplopku/models/envelope_model.dart';
import 'package:amplopku/screens/envelope_form_screen.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetupEnvelopeScreen extends StatefulWidget {
  const SetupEnvelopeScreen({super.key});

  @override
  State<SetupEnvelopeScreen> createState() => _SetupEnvelopeScreenState();
}

class _SetupEnvelopeScreenState extends State<SetupEnvelopeScreen> {
  double _income = 0;
  bool _isLoading = true;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _loadIncome();
  }

  Future<void> _loadIncome() async {
    final user = AuthService().currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }

    try {
      final finance = await FirestoreService().getFinance(user.uid);
      final data = finance.data();
      if (!mounted) return;
      setState(() {
        _income = (data?['income'] ?? 0).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat pendapatan: $e')),
      );
    }
  }

  Future<void> _openForm([EnvelopeModel? envelope]) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EnvelopeFormScreen(
          envelope: envelope,
          monthlyIncome: _income,
        ),
      ),
    );
  }

  Future<void> _deleteEnvelope(EnvelopeModel envelope) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus amplop?'),
        content: Text(
          'Amplop "${envelope.nama}" akan dihapus. Transaksi lama tidak ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirestoreService().deleteEnvelope(
        uid: user.uid,
        envelopeId: envelope.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus amplop: $e')),
      );
    }
  }

  Future<void> _finish(List<EnvelopeModel> envelopes) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    if (envelopes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu amplop terlebih dahulu')),
      );
      return;
    }

    final totalBudget = envelopes.fold<double>(0, (sum, item) => sum + item.budget);
    if (_income > 0 && totalBudget > _income) {
      final continueAnyway = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Budget melebihi pendapatan'),
          content: Text(
            'Total budget ${rupiah(totalBudget)} lebih besar dari pendapatan ${rupiah(_income)}. Tetap lanjut?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Periksa Lagi'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tetap Lanjut'),
            ),
          ],
        ),
      );
      if (continueAnyway != true) return;
    }

    setState(() => _isFinishing = true);
    try {
      await FirestoreService().finishSetup(user.uid);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyelesaikan setup: $e')),
      );
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Atur Amplop')), 
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().getEnvelopes(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final envelopes = snapshot.data?.docs
                    .map((doc) => EnvelopeModel.fromMap(doc.id, doc.data()))
                    .toList() ??
                [];
            final totalBudget =
                envelopes.fold<double>(0, (sum, item) => sum + item.budget);
            final remainingIncome = _income - totalBudget;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Buat amplopmu sendiri',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tidak ada amplop otomatis. Tambahkan nama dan nominal sesuai kebutuhanmu.',
                  style: TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Pendapatan bulanan', rupiah(_income)),
                      const SizedBox(height: 10),
                      _summaryRow('Total dialokasikan', rupiah(totalBudget)),
                      const Divider(height: 24),
                      _summaryRow(
                        remainingIncome >= 0 ? 'Belum dialokasikan' : 'Kelebihan budget',
                        rupiah(remainingIncome.abs()),
                        valueColor: remainingIncome >= 0
                            ? AppColors.primary
                            : AppColors.accentRed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Tambah Amplop Baru'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Amplop Saya (${envelopes.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (envelopes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 42,
                          color: AppColors.textGrey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Belum ada amplop',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tekan tombol Tambah Amplop Baru untuk mulai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  )
                else
                  ...envelopes.map(
                    (envelope) => _EnvelopeItem(
                      envelope: envelope,
                      onEdit: () => _openForm(envelope),
                      onDelete: () => _deleteEnvelope(envelope),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isFinishing ? null : () => _finish(envelopes),
                    child: Text(
                      _isFinishing ? 'Menyimpan...' : 'Selesai dan Masuk Dashboard',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EnvelopeItem extends StatelessWidget {
  final EnvelopeModel envelope;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EnvelopeItem({
    required this.envelope,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = envelope.envelopeColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.14),
            child: Icon(_iconFromName(envelope.icon), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  envelope.nama,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${rupiah(envelope.budget)} • ${envelope.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFromName(String value) {
    switch (value) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'bill':
        return Icons.receipt_long_rounded;
      case 'saving':
        return Icons.savings_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }
}
