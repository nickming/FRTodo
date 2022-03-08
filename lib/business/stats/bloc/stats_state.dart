part of 'stats_bloc.dart';

enum StatsStatus { initial, loading, success, failure }

class StatState extends Equatable {
  final StatsStatus status;
  final int completedTodos;
  final int activeTodos;

  const StatState(
      {this.status = StatsStatus.initial,
      this.completedTodos = 0,
      this.activeTodos = 0});

  StatState copyWith(
      {StatsStatus? status, int? completedTodos, int? activeTodos}) {
    return StatState(
        status: status ?? this.status,
        completedTodos: completedTodos ?? this.completedTodos,
        activeTodos: activeTodos ?? this.activeTodos);
  }

  @override
  List<Object?> get props => [status, completedTodos, activeTodos];
}
