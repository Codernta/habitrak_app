import 'package:equatable/equatable.dart';

/// Represents a soulful, royalty-free audio soundscape curated for yoga,
/// meditation, and mindful breathing practice (ranging from 1 to 5 minutes).
class SoulfulTrack extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String category;
  final int durationSeconds;
  final String audioUrl;
  final List<String> tags;
  final String license;
  final String description;
  final bool isLocalAsset;

  const SoulfulTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.category,
    required this.durationSeconds,
    required this.audioUrl,
    required this.tags,
    this.license = '100% Free • Royalty-Free • CC0 / Public Domain',
    this.description = 'Soothing ambient audio for mindful focus and serenity.',
    this.isLocalAsset = false,
  });

  /// Formatted duration string e.g. "02:14"
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Human-friendly display label e.g. "2 mins"
  String get displayDurationMinutes {
    final minutes = (durationSeconds / 60.0).round();
    return '$minutes ${minutes == 1 ? 'min' : 'mins'}';
  }

  SoulfulTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? category,
    int? durationSeconds,
    String? audioUrl,
    List<String>? tags,
    String? license,
    String? description,
    bool? isLocalAsset,
  }) {
    return SoulfulTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      category: category ?? this.category,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioUrl: audioUrl ?? this.audioUrl,
      tags: tags ?? this.tags,
      license: license ?? this.license,
      description: description ?? this.description,
      isLocalAsset: isLocalAsset ?? this.isLocalAsset,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    category,
    durationSeconds,
    audioUrl,
    tags,
    license,
    description,
    isLocalAsset,
  ];
}
