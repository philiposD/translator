import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presenters/translation_presenter.dart';
import 'ui/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Static initialization
  await FlutterGemma.initialize();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TranslationPresenter()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gemma Translator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Translator App'),
    );
  }
}
