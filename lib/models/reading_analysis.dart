class ReadingAnalysis {
  final String userId;
  final String analysisPeriod;
  final int totalBooks;
  final AnalysisResult analysis;

  ReadingAnalysis({
    required this.userId,
    required this.analysisPeriod,
    required this.totalBooks,
    required this.analysis,
  });

  factory ReadingAnalysis.fromJson(Map<String, dynamic> json) {
    return ReadingAnalysis(
      userId: json['user_id'] ?? '',
      analysisPeriod: json['analysis_period'] ?? '',
      totalBooks: json['total_books'] ?? 0,
      analysis: AnalysisResult.fromJson(json['analysis'] ?? {}),
    );
  }
}

class AnalysisResult {
  final List<String> favoriteAuthors;
  final String readingFrequency;
  final String readingThemes;
  final String contentAnalysis;
  final String timePattern;
  final List<String> recommendations;
  final List<String> improvementTips;

  AnalysisResult({
    required this.favoriteAuthors,
    required this.readingFrequency,
    required this.readingThemes,
    required this.contentAnalysis,
    required this.timePattern,
    required this.recommendations,
    required this.improvementTips,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      favoriteAuthors: _parseStringList(json['favorite_authors']),
      readingFrequency: json['reading_frequency']?.toString() ?? '',
      readingThemes: json['reading_themes']?.toString() ?? '',
      contentAnalysis: json['content_analysis']?.toString() ?? '',
      timePattern: json['time_pattern']?.toString() ?? '',
      recommendations: _parseStringList(json['recommendations']),
      improvementTips: _parseStringList(json['improvement_tips']),
    );
  }

// 안전한 리스트 파싱 함수 추가
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').toList();
    }
    return [];
  }
}