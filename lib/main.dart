import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'src/db/app_db.dart';
import 'src/ui/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDb.create(); // opens DB
  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final AppDb db;
  const MyApp({Key? key, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<AppDb>.value(
      value: db,
      child: MaterialApp(
        title: 'Martial Notes',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
        ],
        home: const HomePage(),
      ),
    );
  }
}
