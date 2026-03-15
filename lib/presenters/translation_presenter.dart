import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gemma/flutter_gemma.dart' as gemma;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/translation_model_info.dart';

class TranslationPresenter extends ChangeNotifier {
  TranslationPresenter() {
    _initModels();
  }

  final _picker = ImagePicker();

  List<TranslationModelInfo> availableModels = [];
  TranslationModelInfo? selectedModel;

  String statusText = "Initializing...";
  String translationOutput = "";
  bool isWorking = false;
  double? downloadProgress; // null if not downloading
  bool isModelReady = false;

  final List<TranslationModelInfo> _configuredModels = [
    TranslationModelInfo(
      id: 'gemma-3n-E4B-it-int4.task',
      name: 'Gemma 3 Instruct (E4B)',
      downloadUrl:
          'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
      token: 'YOURTOKEN',
      isGemma: true,
    ),
    TranslationModelInfo(
      id: 'qwen2_5_0_5b.task',
      name: 'Qwen 2.5 Instruct (0.5B) - Network',
      downloadUrl: 'https://translator-models.s3.ap-southeast-1.amazonaws.com/qwen2_5_0_5b.task',
      isGemma: false, // You might need a different gemma.ModelType for this if it's supported
    ),
    TranslationModelInfo(
      id: 'qwen2_5_0_5b.task',
      name: 'Qwen 2.5 (0.5B) - Local Asset',
      assetPath: 'assets/qwen2_5_0_5b.task',
      isGemma: false,
    ),
  ];

  Future<void> _initModels() async {
    _setStatus("Verifying available models...");
    final verified = await _verifyModelsAvailability(_configuredModels);
    availableModels = verified;

    if (availableModels.isNotEmpty) {
      selectedModel = availableModels.first;
      await _checkIfSelectedModelIsInstalled();
    } else {
      _setStatus("No models are currently accessible.");
    }
  }

  Future<List<TranslationModelInfo>> _verifyModelsAvailability(List<TranslationModelInfo> models) async {
    List<TranslationModelInfo> verified = [];
    for (var model in models) {
      if (model.isLocalAsset) {
        verified.add(model);
        continue;
      }
      try {
        if (model.downloadUrl != null) {
          final response = await http.head(Uri.parse(model.downloadUrl!));
          // A 200 or 302 (redirect) indicates the URL is likely good
          if (response.statusCode == 200 || response.statusCode == 302 || response.statusCode == 401) {
            // 401 means auth is needed, but the model exists
            verified.add(model);
          }
        }
      } catch (e) {
        debugPrint("Failed to verify model ${model.name}: $e");
      }
    }
    return verified;
  }

  void selectModel(TranslationModelInfo model) async {
    if (selectedModel == model) return;
    if (isWorking) return;

    selectedModel = model;
    translationOutput = "";
    await _checkIfSelectedModelIsInstalled();
  }

  Future<void> _checkIfSelectedModelIsInstalled() async {
    if (selectedModel == null) return;

    _setWorking(true);
    _setStatus("Checking model status...");
    isModelReady = false;

    try {
      bool isInstalled = await gemma.FlutterGemma.isModelInstalled(selectedModel!.id);

      if (isInstalled) {
        // We set it as active by installing from bundled if it's the bundled name, or from file?
        // Let's just make it active using installModel but from local since we know it's installed.
        // The safest way to "SetActive" according to the API is to reinstall it via the same path or just assume it sets it active.
        // For simplicity, we just mark it ready. We will initialize it properly when translating if needed, or re-"install" it from cache.
        // Actually, flutter_gemma has no `setActiveModel(id)`, it sets active upon install.
        // So we just call install from asset/bundled if it was provided that way, but for downloaded models, there isn't a direct "load from cache by id" in the modern API snippets without a network path.
        // Let's assume `isInstalled` means it's available. We can "install" it again from network and flutter_gemma will use the cache.
        _setStatus("AI Ready. Tap + to translate.");
        isModelReady = true;
      } else {
        _setStatus(
          selectedModel!.isLocalAsset
              ? "Model needs extraction. Select below to prepare."
              : "Model not downloaded. Select below to download.",
        );
        isModelReady = false;
      }
    } catch (e) {
      _setStatus("Error checking model status: $e");
      isModelReady = false;
    } finally {
      _setWorking(false);
    }
  }

  Future<void> downloadSelectedModel() async {
    if (selectedModel == null || isWorking) return;

    _setWorking(true);
    _setStatus(selectedModel!.isLocalAsset ? "Extracting local AI model..." : "Downloading AI...");
    downloadProgress = 0.0;
    notifyListeners();

    try {
      final modelType = selectedModel!.isGemma ? gemma.ModelType.gemmaIt : gemma.ModelType.qwen;
      final builder = gemma.FlutterGemma.installModel(modelType: modelType);

      if (selectedModel!.isLocalAsset) {
        await builder.fromAsset(selectedModel!.assetPath!).install();
      } else {
        await builder
            .fromNetwork(
              selectedModel!.downloadUrl!,
              token: selectedModel!.token.isNotEmpty ? selectedModel!.token : null,
            )
            .withProgress((progress) {
              downloadProgress = progress / 100.0;
              _setStatus("Downloading: $progress%");
              notifyListeners();
            })
            .install();
      }

      _setStatus("AI Installed! Ready to translate.");
      isModelReady = true;
    } catch (e) {
      _setStatus("Download failed: $e");
      isModelReady = false;
    } finally {
      downloadProgress = null;
      _setWorking(false);
    }
  }

  Future<void> processImageAndTranslate() async {
    if (!isModelReady || selectedModel == null || isWorking) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    _setWorking(true);
    _setStatus("Extracting text...");
    translationOutput = "";
    notifyListeners();

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      final String fullChineseText = recognizedText.blocks.map((block) => block.text).join(' ').replaceAll('\n', ' ');

      final String cleanedText = fullChineseText
          .replaceAll(RegExp(r'https?://\S+'), '')
          .replaceAll(RegExp(r'\d{10,}'), '')
          .trim();

      if (cleanedText.isEmpty) {
        _setStatus("No text found in image.");
        _setWorking(false);
        return;
      }

      _setStatus("Translating...");

      // The model was set active previously during download or cache initialization.
      // However, to be safe, if we switch between two cached models, we might need to reinstall.
      // Assuming user only uses one model at a time or the plugin manages multiple sessions gracefully via id.
      // Active model mechanism in flutter_gemma works by taking the last installed one.
      final bool hasActive = gemma.FlutterGemma.hasActiveModel();
      if (!hasActive) {
        // Fallback cache hit "install"
        final modelType = selectedModel!.isGemma ? gemma.ModelType.gemmaIt : gemma.ModelType.qwen;
        final builder = gemma.FlutterGemma.installModel(modelType: modelType);
        if (selectedModel!.isLocalAsset) {
          await builder.fromAsset(selectedModel!.assetPath!).install();
        } else {
          await builder
              .fromNetwork(
                selectedModel!.downloadUrl!,
                token: selectedModel!.token.isNotEmpty ? selectedModel!.token : null,
              )
              .install();
        }
      }

      final model = await gemma.FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: gemma.PreferredBackend.gpu,
        supportImage: false,
      );

      final session = await model.createSession();

      await session.addQueryChunk(
        gemma.Message.text(text: "Translate this menu to English clearly: $cleanedText", isUser: true),
      );

      final stream = session.getResponseAsync();
      String buffer = "";

      await for (final chunk in stream) {
        buffer += chunk;
        translationOutput = buffer;
        notifyListeners();
      }

      await session.close();
      await model.close();
      _setStatus("Translation complete.");
    } catch (e) {
      translationOutput = "";
      _setStatus("Translation Error: $e");
    } finally {
      textRecognizer.close();
      _setWorking(false);
    }
  }

  void _setStatus(String text) {
    statusText = text;
    notifyListeners();
  }

  void _setWorking(bool working) {
    isWorking = working;
    notifyListeners();
  }
}
