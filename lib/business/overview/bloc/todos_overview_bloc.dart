import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frtodo/business/overview/models/todos_view_filter.dart';
import 'package:todos_api/todo.dart';
import 'package:todos_repository/todo_repository.dart';

part 'todos_overview_event.dart';

part 'todos_overview_state.dart';

class TodosOverviewBloc extends Bloc<TodosOverviewEvent, TodosOverviewState> {
  final TodoRepository _todoRepository;

  TodosOverviewBloc({required TodoRepository todoRepository})
      : _todoRepository = todoRepository,
        super(const TodosOverviewState()) {
    //事件逻辑绑定
    on<TodoOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<TodosOverviewTodoSaved>(_onTodoSaved);
    on<TodosOverviewTodoCompletionToggled>(_onTodoCompletionToggled);
    on<TodosOverviewUndoDeletionRequested>(_onUndoDeletionRequested);
    on<TodosOverviewFilterChanged>(_onFilterChanged);
    on<TodosOverviewTodoDeleted>(_onTodoDeleted);
    on<TodosOverviewToggleAllRequested>(_onToggleAllRequested);
    on<TodosOverviewClearCompletedRequested>(_onClearCompletedRequested);
  }

  Future<void> _onSubscriptionRequested(TodoOverviewSubscriptionRequested event,
      Emitter<TodosOverviewState> emit) async {
    emit(state.copyWith(status: () => TodosOverviewStatus.loading));
    //emit.forEach()是意义是指每个bloc能够订阅stream并为流中的每个更新发出一个新状态
    //emit.forEach() is not the same forEach() used by lists.
    // This forEach enables the bloc to subscribe to a Stream and emit a new state for each update from the stream.
    await emit.forEach<List<Todo>>(
      _todoRepository.getTodos(),
      onData: (todos) => state.copyWith(
        status: () => TodosOverviewStatus.success,
        todos: () => todos,
      ),
      onError: (_, __) => state.copyWith(
        status: () => TodosOverviewStatus.failure,
      ),
    );
  }

  FutureOr<void> _onTodoSaved(
      TodosOverviewTodoSaved event, Emitter<TodosOverviewState> emit) async {
    emit(state.copyWith(status: () => TodosOverviewStatus.loading));
    await _todoRepository.saveTodo(event.todo);
  }

  FutureOr<void> _onTodoCompletionToggled(
      TodosOverviewTodoCompletionToggled event,
      Emitter<TodosOverviewState> emit) async {
    final newTodo = event.todo.copyWith(isCompleted: event.isCompleted);
    await _todoRepository.saveTodo(newTodo);
  }

  FutureOr<void> _onUndoDeletionRequested(
      TodosOverviewUndoDeletionRequested event,
      Emitter<TodosOverviewState> emit) async {
    assert(state.lastDeletedTodo != null, 'Last deleted todo can not be null!');
    final todo = state.lastDeletedTodo!;
    emit(state.copyWith(lastDeletedTodo: () => null));
    await _todoRepository.saveTodo(todo);
  }

  FutureOr<void> _onFilterChanged(
      TodosOverviewFilterChanged event, Emitter<TodosOverviewState> emit) {
    emit(state.copyWith(filter: () => event.filter));
  }

  FutureOr<void> _onTodoDeleted(
      TodosOverviewTodoDeleted event, Emitter<TodosOverviewState> emit) async {
    final todo = event.todo;
    emit(state.copyWith(lastDeletedTodo: () => todo));
    await _todoRepository.deleteTodo(todo.id);
  }

  FutureOr<void> _onToggleAllRequested(TodosOverviewToggleAllRequested event,
      Emitter<TodosOverviewState> emit) async {
    final areAllCompleted = state.todos.every((element) => element.isCompleted);
    await _todoRepository.completeAll(!areAllCompleted);
  }

  FutureOr<void> _onClearCompletedRequested(
      TodosOverviewClearCompletedRequested event,
      Emitter<TodosOverviewState> emit) async {
    await _todoRepository.clearCompleted();
  }
}
