import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: AppColors.textDark), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(radius: 36, backgroundColor: Color(0xFFFFEDD5), child: Icon(Icons.coffee, size: 36, color: AppColors.accentOrange)),
              const SizedBox(height: 16),
              const Text('Detail Transaksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('-Rp 25.000', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 32),
              _buildDetailItem('Kategori', 'Minuman'),
              _buildDetailItem('Amplop', 'Keinginan'),
              _buildDetailItem('Tanggal', 'Tanggal transaksi'),
              _buildDetailItem('Waktu', '10:30'),
              _buildDetailItem('Catatan', 'Ngopi sore bareng teman.'),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {},
                      child: const Text('Edit', style: TextStyle(color: AppColors.textDark)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFEE2E2), foregroundColor: AppColors.accentRed, elevation: 0),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Hapus Transaksi?'),
                            content: const Text('Apakah anda yakin ingin menghapus data transaksi ini secara permanen?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                              TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Hapus', style: TextStyle(color: AppColors.accentRed))),
                            ],
                          ),
                        );
                      },
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }
}