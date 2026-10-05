import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

// --- EVENTS ---
abstract class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object?> get props => [];
}

class LoadHabitsEvent extends HabitEvent {}

class ToggleHabitEvent extends HabitEvent {
  final String habitId;
  const ToggleHabitEvent(this.habitId);

  @override
  List<Object?> get props => [habitId];
}

class UpdateHabitProgressEvent extends HabitEvent {
  final String habitId;
  final double progress;
  const UpdateHabitProgressEvent(this.habitId, this.progress);

  @override
  List<Object?> get props => [habitId, progress];
}

class AddCustomHabitEvent extends HabitEvent {
  final String title;
  final HabitCategory category;
  final double targetProgress;
  final String unit;
  final String? scheduledTime;

  const AddCustomHabitEvent({
    required this.title,
    required this.category,
    required this.targetProgress,
    required this.unit,
    this.scheduledTime,
  });

  @override
  List<Object?> get props => [
    title,
    category,
    targetProgress,
    unit,
    scheduledTime,
  ];
}

class ResetHabitsEvent extends HabitEvent {}

class ChangeActiveDateEvent extends HabitEvent {
  final DateTime date;
  const ChangeActiveDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

class CompleteActivityHabitEvent extends HabitEvent {
  final HabitCategory category;
  final String? titleKeyword;
  final double? progressAmount;

  const CompleteActivityHabitEvent({
    required this.category,
    this.titleKeyword,
    this.progressAmount,
  });

  @override
  List<Object?> get props => [category, titleKeyword, progressAmount];
}

// --- STATES ---
abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

class HabitInitial extends HabitState {}

class HabitLoading extends HabitState {}

class HabitLoaded extends HabitState {
  final List<Habit> habits;
  final double completionPercentage;
  final DateTime activeDate;

  const HabitLoaded({
    required this.habits,
    required this.completionPercentage,
    required this.activeDate,
  });

  HabitLoaded copyWith({
    List<Habit>? habits,
    double? completionPercentage,
    DateTime? activeDate,
  }) {
    return HabitLoaded(
      habits: habits ?? this.habits,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      activeDate: activeDate ?? this.activeDate,
    );
  }

  @override
  List<Object?> get props => [habits, completionPercentage, activeDate];
}

class HabitError extends HabitState {
  final String message;
  const HabitError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLOC ---
class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final HabitRepository repository;

  HabitBloc({required this.repository}) : super(HabitInitial()) {
    on<LoadHabitsEvent>(_onLoadHabits);
    on<ToggleHabitEvent>(_onToggleHabit);
    on<UpdateHabitProgressEvent>(_onUpdateProgress);
    on<AddCustomHabitEvent>(_onAddCustomHabit);
    on<ResetHabitsEvent>(_onResetHabits);
    on<ChangeActiveDateEvent>(_onChangeActiveDate);
    on<CompleteActivityHabitEvent>(_onCompleteActivityHabit);
  }

  Future<void> _onLoadHabits(
    LoadHabitsEvent event,
    Emitter<HabitState> emit,
  ) async {
    emit(HabitLoading());
    try {
      final habits = await repository.getHabits();
      final percentage = _calculatePercentage(habits);
      emit(
        HabitLoaded(
          habits: habits,
          completionPercentage: percentage,
          activeDate: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(HabitError('Failed to load habits: $e'));
    }
  }

  void _onChangeActiveDate(
    ChangeActiveDateEvent event,
    Emitter<HabitState> emit,
  ) {
    if (state is HabitLoaded) {
      final current = state as HabitLoaded;
      emit(current.copyWith(activeDate: event.date));
    }
  }

  Future<void> _onCompleteActivityHabit(
    CompleteActivityHabitEvent event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final current = state as HabitLoaded;
      try {
        final habits = await repository.getHabits();
        Habit? match;
        if (event.titleKeyword != null) {
          match = habits
              .where(
                (h) => h.title.toLowerCase().contains(
                  event.titleKeyword!.toLowerCase(),
                ),
              )
              .firstOrNull;
        }
        match ??= habits.where((h) => h.category == event.category).firstOrNull;

        if (match != null) {
          if (event.progressAmount != null && match.targetProgress > 1.0) {
            final newProg = (match.currentProgress + event.progressAmount!)
                .clamp(0.0, match.targetProgress);
            await repository.updateHabitProgress(match.id, newProg);
          } else {
            if (!match.isCompleted) {
              await repository.toggleHabitCompletion(match.id);
            }
          }
          final updatedHabits = await repository.getHabits();
          emit(
            current.copyWith(
              habits: updatedHabits,
              completionPercentage: _calculatePercentage(updatedHabits),
            ),
          );
        }
      } catch (e) {
        emit(HabitError('Failed to complete activity habit: $e'));
      }
    }
  }

  Future<void> _onToggleHabit(
    ToggleHabitEvent event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      try {
        await repository.toggleHabitCompletion(event.habitId);
        final habits = await repository.getHabits();
        final percentage = _calculatePercentage(habits);
        emit(
          currentState.copyWith(
            habits: habits,
            completionPercentage: percentage,
          ),
        );
      } catch (e) {
        emit(HabitError('Failed to update habit: $e'));
      }
    }
  }

  Future<void> _onUpdateProgress(
    UpdateHabitProgressEvent event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      try {
        await repository.updateHabitProgress(event.habitId, event.progress);
        final habits = await repository.getHabits();
        final percentage = _calculatePercentage(habits);
        emit(
          currentState.copyWith(
            habits: habits,
            completionPercentage: percentage,
          ),
        );
      } catch (e) {
        emit(HabitError('Failed to update habit progress: $e'));
      }
    }
  }

  Future<void> _onAddCustomHabit(
    AddCustomHabitEvent event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      try {
        final newHabit = Habit(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: event.title,
          category: event.category,
          targetProgress: event.targetProgress,
          currentProgress: 0.0,
          unit: event.unit,
          isCompleted: false,
          scheduledTime: event.scheduledTime,
        );
        await repository.addHabit(newHabit);
        final habits = await repository.getHabits();
        final percentage = _calculatePercentage(habits);
        emit(
          currentState.copyWith(
            habits: habits,
            completionPercentage: percentage,
          ),
        );
      } catch (e) {
        emit(HabitError('Failed to add habit: $e'));
      }
    }
  }

  Future<void> _onResetHabits(
    ResetHabitsEvent event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      try {
        await repository.resetHabits();
        final habits = await repository.getHabits();
        final percentage = _calculatePercentage(habits);
        emit(
          currentState.copyWith(
            habits: habits,
            completionPercentage: percentage,
          ),
        );
      } catch (e) {
        emit(HabitError('Failed to reset: $e'));
      }
    }
  }

  double _calculatePercentage(List<Habit> habits) {
    if (habits.isEmpty) return 0.0;

    // Average progress vs target progress for all habits
    double totalWeight = 0.0;
    double completedWeight = 0.0;

    for (var h in habits) {
      totalWeight += 1.0;
      if (h.isCompleted) {
        completedWeight += 1.0;
      } else {
        completedWeight += (h.currentProgress / h.targetProgress).clamp(
          0.0,
          1.0,
        );
      }
    }

    return (completedWeight / totalWeight) * 100;
  }
}
