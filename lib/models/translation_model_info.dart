class TranslationModelInfo {
  final String id;
  final String name;
  final String downloadUrl;
  final String token; // Required if downloading from HF gated repos
  final bool isGemma; // To help determine model type for flutter_gemma

  TranslationModelInfo({
    required this.id,
    required this.name,
    required this.downloadUrl,
    this.token = '',
    required this.isGemma,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationModelInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
