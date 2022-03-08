import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todos_api/todo.dart';
import 'package:todos_repository/todo_repository.dart';

part 'edit_todo_event.dart';

part 'edit_todo_state.dart';

class EditTodoBloc extends Bloc<EditTodoEvent, EditTodoState> {
  final TodoRepository _todoRepository;

  EditTodoBloc(
      {required TodoRepository todoRepository, required Todo? initialTodo})
      : _todoRepository = todoRepository,
        super(EditTodoState(
            initialTodo: initialTodo,
            title: initialTodo?.title ?? '',
            description: initialTodo?.description ?? '')) {
    on<EditTodoTitleChanged>(_onTitleChanged);
    on<EditTodoDescriptionChanged>(_onDescriptionChanged);
    on<EditTodoSubmitted>(_onSubmitted);
  }

  FutureOr<void> _onTitleChanged(
      EditTodoTitleChanged event, Emitter<EditTodoState> emit) {
    emit(state.copyWith(title: event.title));
  }

  FutureOr<void> _onDescriptionChanged(
      EditTodoDescriptionChanged event, Emitter<EditTodoState> emit) {
    emit(state.copyWith(description: event.description));
  }

  FutureOr<void> _onSubmitted(
      EditTodoSubmitted event, Emitter<EditTodoState> emit) async {
    emit(state.copyWith(status: EditTodoStatus.loading));
    final todo = (state.initialTodo ?? Todo(title: ''))
        .copyWith(title: state.title, description: state.description);

    try {
      await _todoRepository.saveTodo(todo);
      emit(state.copyWith(status: EditTodoStatus.success));
    } catch (e) {
      emit(state.copyWith(status: EditTodoStatus.failure));
    }
  }
}
