import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final _picker = ImagePicker();
  String text = 'Not Translated';

  void pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // 1. Initialize Local OCR (Chinese)
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

    // 2. Initialize Local Translator
    final onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.chinese,
      targetLanguage: TranslateLanguage.english,
    );

    try {
      // 3. Process Image for OCR
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      // 4. JOIN THE TEXT: Extract all blocks and join with newlines/spaces
      // This gives the translator the full context of the paragraph.
      final String fullChineseText = recognizedText.blocks
          .map((block) => block.text)
          .join(' ') // Joins separate lines into a continuous thought
          .replaceAll('\n', ' '); // Removes hard breaks that break translation logic

      if (fullChineseText.trim().isEmpty) {
        setState(() => text = "No text found in image");
        return;
      }

      // 5. Translate the unified string
      final String translatedText = await onDeviceTranslator.translateText(fullChineseText);

      setState(() {
        text = translatedText;
      });

    } catch (e) {
      setState(() => text = "Error: $e");
    } finally {
      // 6. Clean up resources (Crucial for mobile performance)
      textRecognizer.close();
      onDeviceTranslator.close();
    }
  }

  void _incrementCounter()  {
    setState(()  {
      _counter++;
    });

    pickImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(text)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
