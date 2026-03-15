class TranslationModelInfo {
  final String id;
  final String name;
  final String? downloadUrl;
  final String? assetPath;
  final String token; // Required if downloading from HF gated repos
  final bool isGemma; // To help determine model type for flutter_gemma

  TranslationModelInfo({
    required this.id,
    required this.name,
    this.downloadUrl,
    this.assetPath,
    this.token = '',
    required this.isGemma,
  }) : assert(downloadUrl != null || assetPath != null, 'Must provide either a downloadUrl or an assetPath');

  bool get isLocalAsset => assetPath != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationModelInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}
