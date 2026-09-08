import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/core/utils/currency.dart';
import 'package:amplopku/models/transaction_model.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';

import 'package:flutter/material.dart';


class CalendarScreen extends StatefulWidget {

  const CalendarScreen({
    super.key,
  });


  @override
  State<CalendarScreen> createState() =>
      _CalendarScreenState();

}



class _CalendarScreenState extends State<CalendarScreen> {


  DateTime selectedDate = DateTime.now();



  Future<void> _pickDate() async {


    final DateTime? picked =
        await showDatePicker(

      context: context,

      initialDate: selectedDate,

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),

    );


    if (picked != null) {

      setState(() {

        selectedDate = picked;

      });

    }

  }




  bool _sameDate(
    DateTime a,
    DateTime b,
  ) {

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;

  }




  @override
  Widget build(BuildContext context) {


    final user =
        AuthService().currentUser;



    if (user == null) {

      return const Scaffold(

        body: Center(

          child:
              CircularProgressIndicator(),

        ),

      );

    }




    return Scaffold(


      appBar: AppBar(

        title:
            const Text(
              'Kalender Transaksi',
            ),

      ),




      body: SafeArea(


        child: StreamBuilder(


          stream:
              FirestoreService()
                  .getTransactions(
                    user.uid,
                  ),



          builder: (context, snapshot) {


            if (snapshot.connectionState ==
                ConnectionState.waiting) {

              return const Center(

                child:
                    CircularProgressIndicator(),

              );

            }



            if (!snapshot.hasData) {

              return const Center(

                child:
                    Text(
                      'Belum ada transaksi',
                    ),

              );

            }





            final transactions =
                snapshot.data!.docs
                    .map(
                      (doc) =>
                          TransactionModel.fromMap(
                            doc.id,
                            doc.data(),
                          ),
                    )
                    .where(
                      (tx) =>
                          _sameDate(
                            tx.date,
                            selectedDate,
                          ),
                    )
                    .toList();







            return ListView(

              padding:
                  const EdgeInsets.all(24),



              children: [



                InkWell(

                  onTap:
                      _pickDate,


                  borderRadius:
                      BorderRadius.circular(18),


                  child: Container(

                    padding:
                        const EdgeInsets.all(16),


                    decoration:
                        BoxDecoration(

                      color:
                          AppColors.primary
                              .withOpacity(.08),


                      borderRadius:
                          BorderRadius.circular(18),


                    ),



                    child: Row(

                      children: [


                        const Icon(

                          Icons.calendar_month,

                          color:
                              AppColors.primary,

                        ),



                        const SizedBox(
                          width: 12,
                        ),



                        Expanded(

                          child: Text(

                            formatDate(
                              selectedDate,
                            ),


                            style:
                                const TextStyle(

                              fontWeight:
                                  FontWeight.w900,

                              fontSize:
                                  18,

                            ),

                          ),

                        ),



                        const Icon(
                          Icons.expand_more,
                        ),

                      ],

                    ),

                  ),

                ),




                const SizedBox(
                  height: 20,
                ),





                if (transactions.isEmpty)

                  const Center(

                    child:
                        Padding(

                      padding:
                          EdgeInsets.all(30),

                      child:
                          Text(
                            'Tidak ada transaksi pada tanggal ini',
                          ),

                    ),

                  )



                else

                  ...transactions.map(

                    (tx) {


                      final income =
                          tx.type ==
                              TransactionType.income;




                      return Container(

                        margin:
                            const EdgeInsets.only(
                              bottom: 12,
                            ),



                        padding:
                            const EdgeInsets.all(16),



                        decoration:
                            BoxDecoration(

                          color:
                              Theme.of(context)
                                  .cardColor,


                          borderRadius:
                              BorderRadius.circular(18),


                          border:
                              Border.all(

                            color:
                                AppColors.border,

                          ),

                        ),



                        child: Row(

                          children: [


                            CircleAvatar(

                              backgroundColor:

                                  AppColors.primary
                                      .withOpacity(.12),


                              child:
                                  Icon(

                                Icons
                                    .receipt_long,

                                color:
                                    AppColors.primary,

                              ),

                            ),



                            const SizedBox(
                              width: 12,
                            ),




                            Expanded(

                              child: Column(

                                crossAxisAlignment:
                                    CrossAxisAlignment.start,


                                children: [


                                  Text(

                                    tx.title,


                                    style:
                                        const TextStyle(

                                      fontWeight:
                                          FontWeight.w800,

                                    ),

                                  ),



                                  Text(

                                    tx.description.isEmpty
                                        ? 'Tidak ada catatan'
                                        : tx.description,


                                    style:
                                        const TextStyle(

                                      color:
                                          AppColors.textGrey,

                                      fontSize:
                                          12,

                                    ),

                                  ),


                                ],

                              ),

                            ),




                            Text(

                              '${income ? '+' : '-'}${rupiah(tx.amount)}',


                              style:
                                  TextStyle(

                                color:
                                    income

                                        ? AppColors.primary

                                        : AppColors.accentRed,


                                fontWeight:
                                    FontWeight.w900,

                              ),

                            ),



                          ],

                        ),

                      );

                    },

                  ),


              ],

            );


          },


        ),


      ),


    );

  }

}