import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/core/utils/currency.dart';
import 'package:amplopku/models/envelope_model.dart';
import 'package:amplopku/screens/envelope_form_screen.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageEnvelopeScreen extends StatefulWidget {
  const ManageEnvelopeScreen({super.key});

  @override
  State<ManageEnvelopeScreen> createState() => _ManageEnvelopeScreenState();
}

class _ManageEnvelopeScreenState extends State<ManageEnvelopeScreen> {
  double _income = 0;
  bool _loadingIncome = true;

  @override
  void initState() {
    super.initState();
    _loadIncome();
  }

  Future<void> _loadIncome() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final finance = await FirestoreService().getFinance(user.uid);
    if (!mounted) return;
    setState(() {
      _income = (finance.data()?['income'] ?? 0).toDouble();
      _loadingIncome = false;
    });
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

  Future<void> _delete(EnvelopeModel envelope) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus amplop?'),
        content: Text('Yakin ingin menghapus amplop "${envelope.nama}"?'),
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
    await FirestoreService().deleteEnvelope(
      uid: user.uid,
      envelopeId: envelope.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null || _loadingIncome) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Amplop')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Amplop Baru'),
      ),
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

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total budget amplop',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rupiah(totalBudget),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pendapatan bulanan: ${rupiah(_income)}',
                        style: const TextStyle(color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (envelopes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 44,
                          color: AppColors.textGrey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Belum ada amplop',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tekan Amplop Baru untuk menambahkan data sendiri.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  )
                else
                  ...envelopes.map(
                    (envelope) => Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    envelope.envelopeColor.withOpacity(.12),
                                child: Icon(
                                  _iconFromName(envelope.icon),
                                  color: envelope.envelopeColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      envelope.nama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '${rupiah(envelope.budget)} • ${envelope.percentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _openForm(envelope),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Hapus',
                                onPressed: () => _delete(envelope),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: envelope.progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(99),
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              envelope.envelopeColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Terpakai ${rupiah(envelope.spent)}',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Sisa ${rupiah(envelope.balance)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
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
