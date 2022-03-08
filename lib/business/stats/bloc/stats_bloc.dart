import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:todos_api/todo.dart';
import 'package:todos_repository/todo_repository.dart';

part 'stats_event.dart';

part 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatState> {
  final TodoRepository _todoRepository;

  StatsBloc({required TodoRepository todoRepository})
      : _todoRepository = todoRepository,
        super(const StatState()) {
    on<StatsSubscriptionRequested>(_onSubscriptionRequested);
  }

  FutureOr<void> _onSubscriptionRequested(
      StatsSubscriptionRequested event, Emitter<StatState> emit) async {
    emit(state.copyWith(status: StatsStatus.loading));
    await emit.forEach<List<Todo>>(_todoRepository.getTodos(),
        onData: (todos) => state.copyWith(
            status: StatsStatus.success,
            activeTodos: todos.where((element) => !element.isCompleted).length,
            completedTodos:
                todos.where((element) => element.isCompleted).length),
        onError: (_, __) => state.copyWith(status: StatsStatus.failure));
  }
}
