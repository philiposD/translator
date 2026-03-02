import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/flutter_gemma.dart' as gemma; // Use a prefix
import 'package:flutter_gemma/core/image_tokenizer.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Static initialization
  await FlutterGemma.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
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

  @override
  void initState() {
    super.initState();

    _initializeGemma();
  }

  Future<void> _initializeGemma() async {
    try {
      setState(() => text = "Preparing AI model...");
      await initializeLocalAI();
      setState(() => text = "AI Ready. Tap + to translate.");
    } catch (e) {
      setState(() => text = "Setup failed: $e");
    }
  }

  static const String gemmaModelId = 'gemma-3n-E4B-it-int4.task';
  static const String qwenModelId = 'qwen-2.5-1.5b-int4';

  Future<void> initializeLocalAI() async {
    // 1. Check if the model is already installed to save data/time
    bool isInstalled = await gemma.FlutterGemma.isModelInstalled(gemmaModelId);

    final models = await gemma.FlutterGemma.listInstalledModels();

    if (!isInstalled) {
      setState(() => text = "Downloading AI 'Brain' (1.2GB)...");

      await gemma.FlutterGemma.installModel(modelType: gemma.ModelType.gemmaIt)
          .fromNetwork(
            // 'https://huggingface.co/google/gemma-3-1b-it/resolve/main/gemma-3-1b-it-gpu-int4.task',
            // 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.task',
            'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
            token: 'YOUR_HF_TOKEN',
          )
          .withProgress((progress) {
            // Update UI with the actual download percentage
            setState(() => text = "Downloading: ${progress}%");
          })
          .install();

      setState(() => text = "AI Installed! Ready to translate.");
    } else {
      await gemma.FlutterGemma.installModel(modelType: gemma.ModelType.gemmaIt).fromBundled(gemmaModelId).install();

      setState(() => text = "AI is ready (Offline mode)");
    }
  }

  void pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => text = "Extracting text...");

    // --- 1. OCR (Standard) ---
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    final String fullChineseText = recognizedText.blocks.map((block) => block.text).join(' ').replaceAll('\n', ' ');

    final String cleanedText = fullChineseText
        .replaceAll(RegExp(r'https?://\S+'), '') // Remove URLs
        .replaceAll(RegExp(r'\d{10,}'), '') // Remove long serial numbers
        .trim();

    if (cleanedText.isEmpty) {
      setState(() => text = "No text found in image.");
      return;
    }

    // --- 2. LLM Streaming Translation ---
    try {
      setState(() => text = ""); // Clear text for new translation

      final model = await gemma.FlutterGemma.getActiveModel(
        maxTokens: 1024, // Lower tokens = faster first-word latency
        preferredBackend: gemma.PreferredBackend.gpu, // Use GPU for flagship performance
        supportImage: false,
      );

      // Inside your pickImage try block:
      final session = await model.createSession();

      await session.addQueryChunk(
        gemma.Message.text(text: "Translate this menu to English clearly: $cleanedText", isUser: true),
      );

      final stream = session.getResponseAsync();
      String buffer = "";

      await for (final chunk in stream) {
        buffer += chunk;
        // Use a frames-per-second optimization: update UI only if the buffer changed significantly
        // or use a microtask to avoid flooding the UI thread
        setState(() {
          text = buffer;
        });
      }

      await session.close();
      await model.close();
    } catch (e) {
      setState(() => text = "Translation Error: $e");
    } finally {
      textRecognizer.close();
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    pickImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Center(
        child: ListView(
          // mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
            Text(text),
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
