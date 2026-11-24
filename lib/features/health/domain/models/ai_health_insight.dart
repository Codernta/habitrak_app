import 'package:equatable/equatable.dart';

class AIHealthInsight extends Equatable {
  final String id;
  final String date;
  final String title;
  final String summary;
  final List<String> observations;
  final List<String> recommendations;
  final double confidence;
  final String category; // 'morning_briefing', 'trend_alert', 'recovery', 'milestone'
  final DateTime createdAt;

  const AIHealthInsight({
    required this.id,
    required this.date,
    required this.title,
    required this.summary,
    required this.observations,
    required this.recommendations,
    this.confidence = 0.95,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'summary': summary,
      'observations': observations,
      'recommendations': recommendations,
      'confidence': confidence,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AIHealthInsight.fromMap(Map<dynamic, dynamic> map) {
    return AIHealthInsight(
      id: map['id'] as String,
      date: map['date'] as String,
      title: map['title'] as String,
      summary: map['summary'] as String,
      observations: (map['observations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendations: (map['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.95,
      category: map['category'] as String? ?? 'morning_briefing',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        title,
        summary,
        observations,
        recommendations,
        confidence,
        category,
        createdAt,
      ];
}
