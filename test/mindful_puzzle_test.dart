import 'package:flutter_test/flutter_test.dart';
import 'package:habitrak/core/services/notification_service.dart';
import 'package:habitrak/features/mindfulness/data/repositories/mindful_puzzle_repository.dart';

void main() {
  group('NotificationService Cool Phrasing Tests', () {
    test('Notification service contains cool streak rescue messages', () {
      expect(NotificationService.coolStreakMessages.isNotEmpty, true);
      for (final msg in NotificationService.coolStreakMessages) {
        expect(msg.containsKey('title'), true);
        expect(msg.containsKey('body'), true);
        expect(msg['title']!.isNotEmpty, true);
        expect(msg['body']!.isNotEmpty, true);
      }
    });

    test('Cool streak messages mention Zen Garden and streak momentum', () {
      final allText = NotificationService.coolStreakMessages
          .map((m) => '${m['title']} ${m['body']}')
          .join(' ');
      expect(allText.contains('Zen'), true);
      expect(allText.contains('Streak'), true);
    });
  });

  group('MindfulPuzzle Repository Constants Tests', () {
    test('Default initial placed pieces has 7 pieces (78% harmonized)', () {
      expect(MindfulPuzzleRepository.defaultInitialPlaced.length, 7);
      expect(MindfulPuzzleRepository.defaultInitialPlaced.contains(4), false);
      expect(MindfulPuzzleRepository.defaultInitialPlaced.contains(7), false);
    });
  });
}
