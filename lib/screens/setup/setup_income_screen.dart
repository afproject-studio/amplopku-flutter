import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/core/utils/currency.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:flutter/material.dart';

class SetupIncomeScreen extends StatefulWidget{
  const SetupIncomeScreen({super.key});

  @override
  State<SetupIncomeScreen> createState()=>_SetupIncomeScreenState();
}

class _SetupIncomeScreenState extends State<SetupIncomeScreen>{

  final incomeController=
  TextEditingController(text:'5000000');

  bool isLoading=false;


  @override
  void dispose(){

    incomeController.dispose();

    super.dispose();

  }



  Future<void> _next() async{

    final user=
    AuthService().currentUser;


    final income=
    double.tryParse(
      incomeController.text
          .replaceAll('.','')
          .replaceAll(',','')
          .trim(),
    )??0;



    if(user==null){

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (_)=>false,
      );

      return;

    }



    if(income<=0){

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content:
          Text(
            'Masukkan saldo awal yang valid',
          ),
        ),

      );

      return;

    }



    setState(()=>isLoading=true);



    try{


      await FirestoreService().saveIncome(

        uid:user.uid,

        income:income,

        incomeDate:DateTime.now(),

      );



      if(!mounted)return;



      Navigator.pushNamed(
        context,
        '/setup-envelope',
      );


    }catch(e){


      if(!mounted)return;



      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content:
          Text(
            e.toString()
                .replaceFirst(
                'Exception: ',
                ''
            ),
          ),
        ),

      );


    }finally{


      if(mounted){

        setState(
              ()=>isLoading=false,
        );

      }


    }

  }
    @override
  Widget build(BuildContext context){

    final preview=
    double.tryParse(
      incomeController.text
          .replaceAll('.','')
          .replaceAll(',',''),
    )??0;


    final today=
    DateTime.now();



    return Scaffold(

      appBar:
      AppBar(
        title:
        const Text(
          'Setup Saldo Awal',
        ),
      ),



      body:SafeArea(

        child:SingleChildScrollView(

          padding:
          const EdgeInsets.all(24),


          child:Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,


            children:[


              Text(

                'Berapa saldo awal yang kamu punya?',


                style:
                Theme.of(context)
                    .textTheme
                    .headlineMedium,

              ),



              const SizedBox(
                height:8,
              ),



              const Text(

                'Saldo awal akan dicatat sebagai pemasukan pertama dan otomatis masuk ke laporan sesuai tanggal input.',


                style:
                TextStyle(
                  color:
                  AppColors.textGrey,
                ),

              ),



              const SizedBox(
                height:28,
              ),




              TextField(

                controller:
                incomeController,


                keyboardType:
                TextInputType.number,


                onChanged:
                    (_)=>setState((){}),


                decoration:
                const InputDecoration(

                  prefixText:
                  'Rp ',


                  hintText:
                  '5000000',


                  labelText:
                  'Saldo awal',

                ),

              ),



              const SizedBox(
                height:20,
              ),




              Container(

                width:
                double.infinity,


                padding:
                const EdgeInsets.all(18),



                decoration:
                BoxDecoration(

                  color:
                  AppColors.primary
                      .withOpacity(.10),


                  borderRadius:
                  BorderRadius.circular(20),

                ),



                child:
                Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,


                  children:[


                    const Text(

                      'Tanggal input saldo awal',


                      style:
                      TextStyle(

                        color:
                        AppColors.textGrey,

                      ),

                    ),



                    const SizedBox(
                      height:6,
                    ),



                    Text(

                      '${today.day}-${today.month}-${today.year}',


                      style:
                      const TextStyle(

                        fontSize:
                        18,


                        fontWeight:
                        FontWeight.w700,


                      ),

                    ),


                    const SizedBox(
                      height:4,
                    ),



                    const Text(

                      'Tanggal otomatis dan tidak dapat diubah',


                      style:
                      TextStyle(

                        color:
                        AppColors.textGrey,


                        fontSize:
                        12,

                      ),

                    ),


                  ],

                ),

              ),



              const SizedBox(
                height:24,
              ),



              Container(

                width:
                double.infinity,


                padding:
                const EdgeInsets.all(18),


                decoration:
                BoxDecoration(

                  color:
                  AppColors.primary
                      .withOpacity(.10),


                  borderRadius:
                  BorderRadius.circular(20),

                ),



                child:
                Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,


                  children:[


                    const Text(

                      'Preview saldo awal',


                      style:
                      TextStyle(

                        color:
                        AppColors.textGrey,

                      ),

                    ),



                    const SizedBox(
                      height:6,
                    ),



                    Text(

                      rupiah(preview),


                      style:
                      const TextStyle(

                        color:
                        AppColors.primary,


                        fontSize:
                        24,


                        fontWeight:
                        FontWeight.w800,

                      ),

                    ),


                  ],

                ),

              ),



              const SizedBox(
                height:32,
              ),
                            SizedBox(

                width:
                double.infinity,


                height:
                54,


                child:
                ElevatedButton(


                  onPressed:
                  isLoading
                      ? null
                      : _next,


                  child:
                  Text(

                    isLoading
                        ? 'Menyimpan...'
                        : 'Lanjut Atur Amplop',

                  ),


                ),

              ),


            ],

          ),

        ),

      ),

    );

  }

}