import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/core/utils/icon_helper.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';



class SavingTargetScreen extends StatefulWidget {

  const SavingTargetScreen({
    super.key,
  });


  @override
  State<SavingTargetScreen> createState() =>
      _SavingTargetScreenState();

}





class _SavingTargetScreenState
    extends State<SavingTargetScreen> {



  final titleController =
      TextEditingController();



  final targetController =
      TextEditingController();



  final currentController =
      TextEditingController();





  String rupiah(double value){

    return
        'Rp ${value.toStringAsFixed(0)}';

  }







  Future<void> _showAddTarget() async {


    titleController.clear();

    targetController.clear();

    currentController.clear();




    showDialog(

      context: context,

      builder: (context){


        return AlertDialog(


          title:
              const Text(
                'Tambah Target Tabungan',
              ),




          content:

          Column(

            mainAxisSize:
                MainAxisSize.min,


            children: [



              TextField(

                controller:
                    titleController,


                decoration:
                    const InputDecoration(

                  labelText:
                      'Nama Target',

                  hintText:
                      'Contoh: Beli Laptop',

                ),

              ),





              TextField(

                controller:
                    targetController,


                keyboardType:
                    TextInputType.number,


                decoration:
                    const InputDecoration(

                  labelText:
                      'Target Dana',

                ),

              ),





              TextField(

                controller:
                    currentController,


                keyboardType:
                    TextInputType.number,


                decoration:
                    const InputDecoration(

                  labelText:
                      'Dana Saat Ini',

                ),

              ),


            ],

          ),





          actions: [



            TextButton(

              onPressed:
                  () => Navigator.pop(context),

              child:
                  const Text(
                    'Batal',
                  ),

            ),





            ElevatedButton(

              onPressed:
                  () async {


                final user =
                    AuthService()
                        .currentUser;



                if(user == null) return;



                await FirestoreService()
                    .addSavingTarget(


                  uid:
                      user.uid,


                  title:
                      titleController.text,


                  targetAmount:
                      double.tryParse(
                        targetController.text,
                      ) ?? 0,


                  currentAmount:
                      double.tryParse(
                        currentController.text,
                      ) ?? 0,


                  deadline:
                      DateTime.now(),


                );



                if(context.mounted){

                  Navigator.pop(context);

                }


              },

              child:
                  const Text(
                    'Simpan',
                  ),

            ),


          ],


        );


      },


    );


  }









  Future<void> _showAddMoney(

    String id,

  ) async {


    final controller =
        TextEditingController();



    showDialog(

      context: context,

      builder:(context){


        return AlertDialog(


          title:
              const Text(
                'Tambah Dana',
              ),




          content:

          TextField(

            controller:
                controller,


            keyboardType:
                TextInputType.number,


            decoration:
                const InputDecoration(

              labelText:
                  'Jumlah Dana',

            ),

          ),





          actions:[



            TextButton(

              onPressed:
                  (){
                    Navigator.pop(context);
                  },

              child:
                  const Text(
                    'Batal',
                  ),

            ),




            ElevatedButton(

              onPressed:
                  () async {


                final user =
                    AuthService()
                        .currentUser;



                if(user == null) return;



                await FirestoreService()
                    .addSavingAmount(


                  uid:
                      user.uid,


                  targetId:
                      id,


                  amount:
                      double.tryParse(
                        controller.text,
                      ) ?? 0,


                );



                if(context.mounted){

                  Navigator.pop(context);

                }


              },


              child:
                  const Text(
                    'Tambah',
                  ),

            )


          ],


        );


      },

    );


  }









  Future<void> _deleteTarget(

    String id,

  ) async {


    final user =
        AuthService()
            .currentUser;



    if(user == null) return;




    await FirestoreService()
        .deleteSavingTarget(


      uid:
          user.uid,


      targetId:
          id,


    );


  }









  Future<void> _editTarget(

    String id,

    Map<String,dynamic> data,

  ) async {


    titleController.text =
        data['title'] ?? '';



    targetController.text =
        data['targetAmount']
            .toString();



    currentController.text =
        data['currentAmount']
            .toString();






    showDialog(

      context: context,

      builder:(context){


        return AlertDialog(


          title:
              const Text(
                'Edit Target',
              ),



          content:

          Column(

            mainAxisSize:
                MainAxisSize.min,


            children:[



              TextField(

                controller:
                    titleController,

                decoration:
                    const InputDecoration(

                  labelText:
                      'Nama Target',

                ),

              ),



              TextField(

                controller:
                    targetController,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(

                  labelText:
                      'Target',

                ),

              ),



              TextField(

                controller:
                    currentController,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(

                  labelText:
                      'Saat Ini',

                ),

              ),



            ],

          ),




          actions:[



            ElevatedButton(

              onPressed:
                  () async {



                final user =
                    AuthService()
                        .currentUser;



                if(user == null) return;



                await FirestoreService()
                    .updateSavingTarget(


                  uid:
                      user.uid,


                  targetId:
                      id,


                  title:
                      titleController.text,


                  targetAmount:
                      double.tryParse(
                        targetController.text,
                      ) ?? 0,


                  currentAmount:
                      double.tryParse(
                        currentController.text,
                      ) ?? 0,


                  deadline:
                      DateTime.now(),


                );



                if(context.mounted){

                  Navigator.pop(context);

                }


              },


              child:
                  const Text(
                    'Simpan',
                  ),


            )



          ],


        );


      },


    );


  }









  @override
  Widget build(BuildContext context){


    final user =
        AuthService()
            .currentUser;




    return Scaffold(



      appBar:
          AppBar(

        title:
            const Text(
              'Target Tabungan',
            ),



        actions:[


          IconButton(

            icon:
                const Icon(
                  Icons.add,
                ),

            onPressed:
                _showAddTarget,

          )


        ],


      ),






      body:


      StreamBuilder<

          QuerySnapshot<Map<String,dynamic>>

      >(


        stream:

        FirestoreService()
            .getSavingTargets(
              user!.uid,
            ),



        builder:
            (context,snapshot){



          if(!snapshot.hasData){

            return const Center(

              child:
                  CircularProgressIndicator(),

            );

          }






          final docs =
              snapshot.data!.docs;





          if(docs.isEmpty){

            return const Center(

              child:
                  Text(
                    'Belum ada target tabungan',
                  ),

            );

          }





          return ListView.builder(


            padding:
                const EdgeInsets.all(24),



            itemCount:
                docs.length,



            itemBuilder:
                (context,index){



              final doc =
                  docs[index];



              final data =
                  doc.data();





              final target =
                  (data['targetAmount'] ?? 0)
                      .toDouble();




              final current =
                  (data['currentAmount'] ?? 0)
                      .toDouble();





              final progress =
                  target == 0
                  ? 0
                  : current / target;





              return Container(



                margin:
                    const EdgeInsets.only(
                      bottom:16,
                    ),




                padding:
                    const EdgeInsets.all(18),




                decoration:
                    BoxDecoration(

                  color:
                      Colors.white,


                  borderRadius:
                      BorderRadius.circular(20),


                  border:
                      Border.all(

                    color:
                        AppColors.border,

                  ),

                ),





                child:
                    Row(


                  children:[



                    CircleAvatar(

                      child:
                          Icon(

                        IconHelper.getIcon(
                          data['icon'],
                        ),

                      ),

                    ),




                    const SizedBox(
                      width:12,
                    ),





                    Expanded(

                      child:

                      Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,


                        children:[



                          Text(

                            data['title'],

                            style:
                                const TextStyle(

                              fontWeight:
                                  FontWeight.bold,

                              fontSize:
                                  17,

                            ),

                          ),




                          Text(

                            '${rupiah(current)} / ${rupiah(target)}',

                          ),




                          LinearProgressIndicator(

                            value:
                                progress.clamp(
                                  0,
                                  1,
                                ),

                          ),




                        ],


                      ),

                    ),





                    PopupMenuButton(

                      itemBuilder:
                          (context)=>[


                        const PopupMenuItem(

                          value:
                              'edit',

                          child:
                              Text(
                                'Edit',
                              ),

                        ),



                        const PopupMenuItem(

                          value:
                              'money',

                          child:
                              Text(
                                'Tambah Dana',
                              ),

                        ),



                        const PopupMenuItem(

                          value:
                              'delete',

                          child:
                              Text(
                                'Hapus',
                              ),

                        ),


                      ],



                      onSelected:
                          (value){


                        if(value=='edit'){

                          _editTarget(
                            doc.id,
                            data,
                          );

                        }



                        if(value=='money'){

                          _showAddMoney(
                            doc.id,
                          );

                        }



                        if(value=='delete'){

                          _deleteTarget(
                            doc.id,
                          );

                        }


                      },

                    )



                  ],


                ),


              );



            },


          );



        },


      ),


    );


  }



}