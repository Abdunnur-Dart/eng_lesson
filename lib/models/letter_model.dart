
/// Модель, представляющая отдельную букву
class LetterModel {
  final int id;
  final String title;
  final String description;
  final List<VariationModel> variations;
  final List<WordModel> words;

  LetterModel({
    required this.id,
    required this.title,
    required this.description,
    required this.variations,
    required this.words,
  });

  /// Фабричный конструктор для создания объекта из Map (JSON)
  factory LetterModel.fromJson(Map<String, dynamic> json) {
    return LetterModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      variations: (json['variations'] as List<dynamic>?)
              ?.map((e) => VariationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => WordModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Преобразование объекта обратно в Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'variations': variations.map((e) => e.toJson()).toList(),
      'words': words.map((e) => e.toJson()).toList(),
    };
  }
}

/// Модель вариации написания или огласовки
class VariationModel {
  final String symbol;
  final String transcription;
  final String position;

  VariationModel({
    required this.symbol,
    required this.transcription,
    required this.position,
  });

  factory VariationModel.fromJson(Map<String, dynamic> json) {
    return VariationModel(
      symbol: json['symbol'] as String? ?? '',
      transcription: json['transcription'] as String? ?? '',
      position: json['position'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'transcription': transcription,
      'position': position,
    };
  }
}

/// Модель примера слова
class WordModel {
  final String word;
  final String translation;

  WordModel({
    required this.word,
    required this.translation,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      word: json['word'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
    };
  }
}