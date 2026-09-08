
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:amplopku/app.dart';
import 'package:amplopku/providers/theme_provider.dart';


void main() {

  testWidgets(
    'App builds and shows splash screen',
    (WidgetTester tester) async {


      await tester.pumpWidget(

        ChangeNotifierProvider(

          create: (_) => ThemeProvider(),

          child: const AmplopKuApp(),

        ),

      );


      await tester.pump();



      // Sesuaikan dengan teks SplashScreen AmplopKu
      expect(
        find.text('AmplopKu'),
        findsOneWidget,
      );


    },
  );

}