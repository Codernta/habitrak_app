import 'package:flutter_test/flutter_test.dart';
import 'package:habitrak/features/music/models/soulful_track.dart';
import 'package:habitrak/features/music/services/soulful_music_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoulfulTrack Entity Tests', () {
    test('Track instantiates with correct values and formatted duration', () {
      const track = SoulfulTrack(
        id: 'test_track',
        title: 'Zen Morning Flow',
        artist: 'Habitrak Sanctuary',
        category: 'Yoga Flow',
        durationSeconds: 134, // 2m 14s
        audioUrl: 'https://example.com/audio.mp3',
        tags: ['Yoga', 'Zen'],
      );

      expect(track.id, 'test_track');
      expect(track.title, 'Zen Morning Flow');
      expect(track.formattedDuration, '02:14');
      expect(track.displayDurationMinutes, '2 mins');
      expect(track.isLocalAsset, false);
      expect(track.license, contains('Royalty-Free'));
    });

    test('copyWith updates specified fields correctly', () {
      const track = SoulfulTrack(
        id: '1',
        title: 'Track 1',
        artist: 'Artist 1',
        category: 'Meditation',
        durationSeconds: 120,
        audioUrl: 'url1',
        tags: ['Calm'],
      );

      final updated = track.copyWith(
        title: 'Updated Title',
        durationSeconds: 180,
      );
      expect(updated.title, 'Updated Title');
      expect(updated.durationSeconds, 180);
      expect(updated.formattedDuration, '03:00');
      expect(updated.artist, 'Artist 1');
    });
  });

  group('SoulfulMusicService Tests', () {
    final service = SoulfulMusicService();

    test('All curated tracks are between 1 and 5 minutes (60s to 300s)', () {
      expect(SoulfulMusicService.curatedTracks, isNotEmpty);

      for (final track in SoulfulMusicService.curatedTracks) {
        expect(
          track.durationSeconds,
          greaterThanOrEqualTo(60),
          reason: '${track.title} is shorter than 1 minute',
        );
        expect(
          track.durationSeconds,
          lessThanOrEqualTo(300),
          reason: '${track.title} is longer than 5 minutes',
        );
        expect(track.audioUrl, isNotEmpty);
        expect(track.license, isNotEmpty);
      }
    });

    test('getTodaysTrack returns a valid track deterministically', () {
      final todayTrack = service.getTodaysTrack();
      expect(todayTrack, isNotNull);
      expect(todayTrack.title, isNotEmpty);
      expect(todayTrack.durationSeconds, inInclusiveRange(60, 300));
    });

    test('getNextTrack cycles through catalog', () {
      final first = SoulfulMusicService.curatedTracks.first;
      final next = service.getNextTrack(first);
      expect(next.id, SoulfulMusicService.curatedTracks[1].id);
    });

    test('searchTracks filters by keyword query correctly', () async {
      final yogaMatches = await service.searchTracks('yoga');
      expect(yogaMatches, isNotEmpty);
      expect(
        yogaMatches.any(
          (t) =>
              t.title.toLowerCase().contains('yoga') ||
              t.category.toLowerCase().contains('yoga') ||
              t.tags.any((tag) => tag.toLowerCase().contains('yoga')),
        ),
        isTrue,
      );

      final rainMatches = await service.searchTracks('rain');
      expect(rainMatches, isNotEmpty);
      expect(
        rainMatches.any((t) => t.title.toLowerCase().contains('rain')),
        isTrue,
      );
    });
  });
}
