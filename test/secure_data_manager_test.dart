import 'package:flutter_test/flutter_test.dart';
import 'package:habitrak/core/security/secure_data_manager.dart';
import 'package:habitrak/features/habit/domain/entities/habit.dart';

void main() {
  group('SecureDataManager Tests', () {
    late SecureDataManager manager;

    setUp(() {
      manager = SecureDataManager();
    });

    test('Sanitizes malicious script and HTML tags from text inputs', () {
      const malicious =
          '<script>alert("xss")</script>Morning Meditation<iframe src="evil.com"></iframe>';
      final clean = manager.sanitizeText(malicious);

      expect(clean.contains('<script>'), isFalse);
      expect(clean.contains('<iframe>'), isFalse);
      expect(clean.contains('alert("xss")'), isTrue);
      expect(clean, contains('Morning Meditation'));
    });

    test('Strips ASCII control characters and null bytes', () {
      const contaminated = 'Zen\x00Focus\x07Mind\x1F';
      final clean = manager.sanitizeText(contaminated);

      expect(clean, 'ZenFocusMind');
    });

    test('Enforces maximum length bounds on inputs', () {
      final longString = 'A' * 500;
      final bounded = manager.sanitizeText(longString, maxLength: 80);

      expect(bounded.length, 80);
    });

    test('Sanitizes and bounds numeric inputs', () {
      expect(manager.sanitizeNumeric(5.0, min: 0.0, max: 10.0), 5.0);
      expect(manager.sanitizeNumeric(-3.0, min: 0.0, max: 10.0), 0.0);
      expect(manager.sanitizeNumeric(150.0, min: 0.0, max: 100.0), 100.0);
      expect(manager.sanitizeNumeric(double.nan, min: 1.0, max: 10.0), 1.0);
      expect(
        manager.sanitizeNumeric(double.infinity, min: 1.0, max: 10.0),
        1.0,
      );
    });

    test('Validates habit inputs correctly', () {
      expect(
        manager.validateHabitInput(title: 'Read Book', targetProgress: 20.0),
        isTrue,
      );
      expect(
        manager.validateHabitInput(title: '   ', targetProgress: 20.0),
        isFalse,
      );
      expect(
        manager.validateHabitInput(title: 'Walk', targetProgress: 0.0),
        isFalse,
      );
      expect(
        manager.validateHabitInput(title: 'Walk', targetProgress: double.nan),
        isFalse,
      );
    });

    test('Validates reflection text correctly', () {
      expect(manager.validateReflectionText('Grateful for sunrise.'), isTrue);
      expect(manager.validateReflectionText('   '), isFalse);
    });

    test('Computes deterministic SHA-256 and verifies data integrity', () {
      final data = {
        'userName': 'Jordan Smith',
        'streak': 12,
        'habits': ['Meditation', 'Hydration'],
      };

      final checksum = manager.computeDataChecksum(data);
      expect(checksum.length, 64); // SHA-256 hex string length

      expect(manager.verifyDataIntegrity(data, checksum), isTrue);

      final tamperedData = {
        'userName': 'Tampered User',
        'streak': 99,
        'habits': ['Meditation', 'Hydration'],
      };
      expect(manager.verifyDataIntegrity(tamperedData, checksum), isFalse);
    });

    test('Exports secure user data bundle with integrity metadata', () {
      const habit = Habit(
        id: '1',
        title: 'Morning Breathwork',
        category: HabitCategory.mindfulness,
        targetProgress: 1.0,
        currentProgress: 1.0,
        isCompleted: true,
        streak: 5,
      );

      final exported = manager.exportSecureUserData(
        userName: 'Alex Rivers',
        habits: [habit],
        habitHistory: [
          {
            'date': '2026-10-11',
            'completedCount': 1,
            'totalHabits': 1,
            'completedHabitIds': ['1'],
          },
        ],
        reflections: [
          {
            'id': '1',
            'date': 'Yesterday',
            'text': 'Peaceful morning walk.',
            'createdAt': '2026-10-11T08:00:00.000',
          },
        ],
        goals: [
          {'id': 'g1', 'title': 'Tech detox', 'completed': true},
        ],
        activities: [
          {
            'id': 'a1',
            'type': 'walk',
            'durationMinutes': 30,
            'date': '2026-10-11T09:00:00.000',
          },
        ],
      );

      expect(exported['metadata'], isNotNull);
      expect(exported['metadata']['integritySha256'], isNotEmpty);
      expect(exported['data']['profile']['userName'], 'Alex Rivers');
      expect((exported['data']['habits'] as List).length, 1);
      expect((exported['data']['habitHistory'] as List).length, 1);

      // Verify bundle integrity
      final payload = exported['data'] as Map<String, dynamic>;
      final hash = exported['metadata']['integritySha256'] as String;
      expect(manager.verifyDataIntegrity(payload, hash), isTrue);
    });
  });
}
