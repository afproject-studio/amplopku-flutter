import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/core/utils/currency.dart';
import 'package:amplopku/core/utils/icon_helper.dart';
import 'package:amplopku/models/envelope_model.dart';
import 'package:amplopku/models/transaction_model.dart';
import 'package:amplopku/screens/profil_screen.dart';
import 'package:amplopku/screens/report_screen.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.onOpenReport,
  });

  /// Dipanggil oleh navigasi utama agar tombol Laporan di dashboard
  /// memilih tab Laporan, bukan membuka halaman baru di atas dashboard.
  final VoidCallback? onOpenReport;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if(user == null){
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final firestore = FirestoreService();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
          stream: firestore.financeStream(user.uid),
          builder: (context,financeSnapshot){

            final financeData = financeSnapshot.data?.data() ?? {};

            final rawFinanceIncome = financeData['income'];
            final financeIncome = rawFinanceIncome is num
                ? rawFinanceIncome.toDouble()
                : double.tryParse(rawFinanceIncome?.toString() ?? '') ?? 0.0;

            return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
              stream: firestore.userStream(user.uid),
              builder: (context,userSnapshot){

                final userData = userSnapshot.data?.data() ?? {};

                final nama =
                    (userData['nama'] ??
                    user.email?.split('@').first ??
                    'Pengguna').toString();

                return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                  stream: firestore.getEnvelopes(user.uid),
                  builder: (context,envelopeSnapshot){

                    final envelopes =
                    envelopeSnapshot.data?.docs
                        .map((doc)=>EnvelopeModel.fromMap(
                      doc.id,
                      doc.data(),
                    ))
                        .toList() ?? [];

                    return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                      stream: firestore.getTransactions(user.uid),
                      builder: (context,transactionSnapshot){

                        final transactions =
                        transactionSnapshot.data?.docs
                            .map((doc)=>TransactionModel.fromMap(
                          doc.id,
                          doc.data(),
                        ))
                            .toList() ?? [];

                        final transactionIncome =
                        transactions
                            .where((t)=>t.type == TransactionType.income)
                            .fold<double>(
                          0,
                              (total,t)=>total+t.amount,
                        );

                        final totalIncome =
                            financeIncome + transactionIncome;

                        final totalExpense =
                        transactions
                            .where((t)=>t.type == TransactionType.expense)
                            .fold<double>(
                          0,
                              (total,t)=>total+t.amount,
                        );

                        final totalBudget =
                        envelopes.fold<double>(
                          0,
                              (total,e)=>total+e.budget,
                        );

                        final saldo =
                            totalIncome - totalExpense;

                        return RefreshIndicator(
                          onRefresh: () async {},
                          child: SingleChildScrollView(
                            physics:
                            const AlwaysScrollableScrollPhysics(),
                            padding:
                            const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children:[

                                _buildHeader(
                                  context,
                                  nama,
                                ),

                                const SizedBox(height:22),

                                _buildBalanceCard(
                                  saldo: saldo,
                                  totalBudget: totalBudget,
                                  totalExpense: totalExpense,
                                  totalIncome: totalIncome,
                                ),

                                const SizedBox(height:24),

                                _buildSectionHeader(
                                  context:context,
                                  title:'Amplop Budget',
                                  actionText:'Kelola',
                                  onPressed:(){
                                    Navigator.pushNamed(
                                      context,
                                      '/manage-envelope',
                                    );
                                  },
                                ),

                                const SizedBox(height:8),

                                if(envelopes.isEmpty)
                                  _emptyCard(
                                    context: context,
                                    icon:Icons.account_balance_wallet_outlined,
                                    title:'Belum ada amplop',
                                    message:'Buat amplop agar pengeluaran dapat mengurangi saldo budget secara otomatis.',
                                  )
                                else
                                  ...envelopes.map(
                                        (e)=>_envelopeCard(context, e),
                                  ),

                                const SizedBox(height:18),

                                _buildSectionHeader(
                                  context:context,
                                  title:'Transaksi Terbaru',
                                  actionText:'Laporan',
                                  onPressed: () {
                                    final openReport = onOpenReport;

                                    if (openReport != null) {
                                      openReport();
                                      return;
                                    }

                                    // Fallback apabila DashboardScreen dibuka
                                    // tanpa MainNavigationScreen.
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ReportScreen(),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height:8),

                                if(transactions.isEmpty)
                                  _emptyCard(
                                    context: context,
                                    icon:Icons.receipt_long_outlined,
                                    title:'Belum ada transaksi',
                                    message:'Gunakan menu Tambah untuk mencatat pemasukan atau pengeluaran.',
                                  )
                                else
                                  ...transactions.take(5).map(
                                        (t)=>_transactionItem(
                                      context,
                                      t,
                                      envelopes,
                                    ),
                                  ),

                                const SizedBox(height:90),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
    Widget _buildHeader(
    BuildContext context,
    String nama,
  ){
    return Row(
      children:[
        Expanded(
          child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Text(
                'Halo, $nama 👋',
                style:TextStyle(
                  color:Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Ringkasan Keuangan',
                style:Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed:(){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:(_)=>const ProfileScreen(),
              ),
            );
          },
          icon:const Icon(
            Icons.person_outline_rounded,
          ),
        ),
      ],
    );
  }


  Widget _buildBalanceCard({
    required double saldo,
    required double totalBudget,
    required double totalExpense,
    required double totalIncome,
  }){
    return Container(
      width:double.infinity,
      padding:const EdgeInsets.all(22),
      decoration:BoxDecoration(
        gradient:const LinearGradient(
          colors:[
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin:Alignment.topLeft,
          end:Alignment.bottomRight,
        ),
        borderRadius:BorderRadius.circular(28),
      ),
      child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,
        children:[
          const Text(
            'Saldo Saat Ini',
            style:TextStyle(
              color:Colors.white70,
            ),
          ),
          const SizedBox(height:8),
          Text(
            rupiah(saldo),
            style:const TextStyle(
              color:Colors.white,
              fontSize:30,
              fontWeight:FontWeight.w900,
            ),
          ),
          const SizedBox(height:20),
          Row(
            children:[
              Expanded(
                child:_miniInfo(
                  'Budget',
                  rupiah(totalBudget),
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width:10),
              Expanded(
                child:_miniInfo(
                  'Pemasukan',
                  rupiah(totalIncome),
                  Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height:10),
          _miniInfo(
            'Pengeluaran',
            rupiah(totalExpense),
            Icons.arrow_upward_rounded,
          ),
        ],
      ),
    );
  }


  Widget _miniInfo(
    String label,
    String amount,
    IconData icon,
  ){
    return Container(
      padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(
        color:Colors.white.withOpacity(0.16),
        borderRadius:BorderRadius.circular(18),
      ),
      child:Row(
        children:[
          Icon(
            icon,
            color:Colors.white,
            size:20,
          ),
          const SizedBox(width:9),
          Expanded(
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(
                  label,
                  style:const TextStyle(
                    color:Colors.white70,
                    fontSize:12,
                  ),
                ),
                const SizedBox(height:3),
                Text(
                  amount,
                  overflow:TextOverflow.ellipsis,
                  style:const TextStyle(
                    color:Colors.white,
                    fontWeight:FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String actionText,
    required VoidCallback onPressed,
  }){
    return Row(
      mainAxisAlignment:MainAxisAlignment.spaceBetween,
      children:[
        Text(
          title,
          style:Theme.of(context)
              .textTheme
              .titleLarge,
        ),
        TextButton(
          onPressed:onPressed,
          child:Text(actionText),
        ),
      ],
    );
  }


  Widget _envelopeCard(
    BuildContext context,
    EnvelopeModel envelope,
  ){
    final color = envelope.envelopeColor;

    return Container(
      margin:const EdgeInsets.only(bottom:14),
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(
        color:Theme.of(context).colorScheme.surface,
        borderRadius:BorderRadius.circular(22),
        border:Border.all(
          color:Theme.of(context).dividerColor,
        ),
      ),
      child:Column(
        children:[
          Row(
            children:[
              CircleAvatar(
                backgroundColor:
                color.withOpacity(0.12),
                child:Icon(
                  IconHelper.getIcon(
                    envelope.icon,
                  ),
                  color:color,
                ),
              ),
              const SizedBox(width:12),
              Expanded(
                child:Text(
                  envelope.nama,
                  style:const TextStyle(
                    fontWeight:FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${envelope.percentage.toStringAsFixed(0)}%',
                style:TextStyle(
                  color:color,
                  fontWeight:FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height:14),
          LinearProgressIndicator(
            value:envelope.progress.clamp(0,1),
            minHeight:9,
            borderRadius:
            BorderRadius.circular(99),
            backgroundColor:
            Theme.of(context).dividerColor,
            valueColor:
            AlwaysStoppedAnimation<Color>(
              color,
            ),
          ),
          const SizedBox(height:10),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children:[
              Text(
                'Terpakai ${rupiah(envelope.spent)}',
                style:TextStyle(
                  color:Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize:12,
                ),
              ),
              Text(
                'Sisa ${rupiah(envelope.balance)}',
                style:const TextStyle(
                  fontWeight:FontWeight.w700,
                  fontSize:12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
    Widget _transactionItem(
    BuildContext context,
    TransactionModel transaction,
    List<EnvelopeModel> envelopes,
  ){
    final envelope =
    _findEnvelope(
      envelopes,
      transaction.envelopeId,
    );

    final isIncome =
        transaction.type ==
            TransactionType.income;

    final color =
    isIncome
        ? AppColors.primary
        : envelope?.envelopeColor ??
        AppColors.accentRed;

    return Container(
      margin:const EdgeInsets.only(
        bottom:8,
      ),
      decoration:BoxDecoration(
        color:Theme.of(context).colorScheme.surface,
        borderRadius:
        BorderRadius.circular(18),
      ),
      child:ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal:10,
          vertical:4,
        ),
        leading:CircleAvatar(
          backgroundColor:
          color.withOpacity(0.12),
          child:Icon(
            IconHelper.getIcon(
              transaction.icon,
            ),
            color:color,
          ),
        ),
        title:Text(
          transaction.title,
          style:const TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
        subtitle:Text(
          isIncome
              ? 'Pemasukan'
              : envelope?.nama ??
              'Tanpa amplop',
        ),
        trailing:Text(
          '${isIncome ? '+' : '-'}${rupiah(transaction.amount)}',
          style:TextStyle(
            color:color,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),
    );
  }


  Widget _emptyCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
  }){
    return Container(
      width:double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:BoxDecoration(
        color:Theme.of(context).colorScheme.surface,
        borderRadius:
        BorderRadius.circular(22),
        border:Border.all(
          color:Theme.of(context).dividerColor,
        ),
      ),
      child:Column(
        children:[
          Icon(
            icon,
            size:34,
            color:
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height:8),
          Text(
            title,
            style:const TextStyle(
              fontWeight:
              FontWeight.w900,
            ),
          ),
          const SizedBox(height:4),
          Text(
            message,
            textAlign:
            TextAlign.center,
            style:TextStyle(
              color:Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }


  EnvelopeModel? _findEnvelope(
    List<EnvelopeModel> envelopes,
    String id,
  ){
    for(final envelope in envelopes){
      if(envelope.id == id){
        return envelope;
      }
    }
    return null;
  }
}