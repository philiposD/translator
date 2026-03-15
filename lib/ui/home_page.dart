import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/translation_model_info.dart';
import '../presenters/translation_presenter.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    // In stateless widgets, we can use context.watch to rebuild on changes
    final presenter = context.watch<TranslationPresenter>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Model Selection
              const Text(
                'Select Translation Model:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDropdown(presenter),
              const SizedBox(height: 16),

              // 2. Status / Progress
              _buildStatusArea(presenter),
              const SizedBox(height: 24),

              // 3. Translation Output
              const Text(
                'Translation Output:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      presenter.translationOutput.isNotEmpty
                          ? presenter.translationOutput
                          : '...',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: presenter.isModelReady && !presenter.isWorking
            ? presenter.processImageAndTranslate
            : null, // Disabled if not ready or currently working
        tooltip: 'Pick Image and Translate',
        backgroundColor: presenter.isModelReady && !presenter.isWorking
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildDropdown(TranslationPresenter presenter) {
    if (presenter.availableModels.isEmpty) {
      return const Text("Checking networks/models...");
    }

    return DropdownButton<TranslationModelInfo>(
      isExpanded: true,
      value: presenter.selectedModel,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      onChanged: presenter.isWorking
          ? null // Disable change if working
          : (TranslationModelInfo? newValue) {
              if (newValue != null) {
                presenter.selectModel(newValue);
              }
            },
      items: presenter.availableModels
          .map<DropdownMenuItem<TranslationModelInfo>>(
              (TranslationModelInfo model) {
        return DropdownMenuItem<TranslationModelInfo>(
          value: model,
          child: Text(model.name),
        );
      }).toList(),
    );
  }

  Widget _buildStatusArea(TranslationPresenter presenter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          presenter.statusText,
          style: TextStyle(
            color: presenter.isWorking ? Colors.blue : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (!presenter.isModelReady && !presenter.isWorking && presenter.selectedModel != null) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: presenter.downloadSelectedModel,
            icon: Icon(presenter.selectedModel!.isLocalAsset ? Icons.folder : Icons.download),
            label: Text(presenter.selectedModel!.isLocalAsset ? 'Extract Local Model' : 'Download Model'),
          ),
        ],
        if (presenter.downloadProgress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: presenter.downloadProgress),
        ],
      ],
    );
  }
}
