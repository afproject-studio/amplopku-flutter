import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();


  await initializeDateFormatting(
    'id_ID',
    null,
  );


  try {

    await Firebase.initializeApp(

      options:
      DefaultFirebaseOptions.currentPlatform,

    );


  } catch (_) {

  }



  runApp(


    ChangeNotifierProvider(


      create: (_) => ThemeProvider(),


      child:

      const AmplopKuApp(),


    ),


  );


}