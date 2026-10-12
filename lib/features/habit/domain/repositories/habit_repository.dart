import '../entities/habit.dart';

abstract class HabitRepository {
  Future<List<Habit>> getHabits();
  Future<void> toggleHabitCompletion(String habitId);
  Future<void> updateHabitProgress(String habitId, double progress);
  Future<void> addHabit(Habit habit);
  Future<void> resetHabits();
  Future<void> syncDailyHabits();
  Future<List<Habit>> getHabitsForDate(DateTime date);
  Future<double> getCompletionPercentageForDate(DateTime date);
}
