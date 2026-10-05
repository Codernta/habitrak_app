import 'package:flutter_test/flutter_test.dart';
import 'package:habitrak/features/habit/domain/entities/habit.dart';

void main() {
  group('Habit Model Tests', () {
    test('Habit instantiation and copyWith work as expected', () {
      const habit = Habit(
        id: '1',
        title: 'Morning Meditation',
        category: HabitCategory.mindfulness,
        targetProgress: 15.0,
        currentProgress: 5.0,
        unit: 'mins',
      );

      expect(habit.id, '1');
      expect(habit.title, 'Morning Meditation');
      expect(habit.category.displayName, 'Mindfulness');
      expect(habit.isCompleted, false);

      final updated = habit.copyWith(currentProgress: 15.0, isCompleted: true);

      expect(updated.currentProgress, 15.0);
      expect(updated.isCompleted, true);
      expect(updated.title, 'Morning Meditation');
    });

    test('Habit category displayName returns correct titles', () {
      expect(HabitCategory.mindfulness.displayName, 'Mindfulness');
      expect(HabitCategory.health.displayName, 'Health');
      expect(HabitCategory.growth.displayName, 'Growth');
    });
  });
}
