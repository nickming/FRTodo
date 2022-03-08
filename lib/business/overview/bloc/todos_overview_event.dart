part of 'todos_overview_bloc.dart';

//事件驱动
abstract class TodosOverviewEvent extends Equatable {
  const TodosOverviewEvent();

  @override
  List<Object> get props => [];
}

class TodoOverviewSubscriptionRequested extends TodosOverviewEvent {
  const TodoOverviewSubscriptionRequested();
}

class TodosOverviewTodoSaved extends TodosOverviewEvent {
  final Todo todo;

  const TodosOverviewTodoSaved(this.todo);

  @override
  List<Object> get props => [todo];
}

class TodosOverviewTodoCompletionToggled extends TodosOverviewEvent {
  const TodosOverviewTodoCompletionToggled({
    required this.todo,
    required this.isCompleted,
  });

  final Todo todo;
  final bool isCompleted;

  @override
  List<Object> get props => [todo, isCompleted];
}

class TodosOverviewUndoDeletionRequested extends TodosOverviewEvent {
  const TodosOverviewUndoDeletionRequested();
}

class TodosOverviewFilterChanged extends TodosOverviewEvent {
  final TodosViewFilter filter;

  const TodosOverviewFilterChanged(this.filter);

  @override
  List<Object> get props => [filter];
}

class TodosOverviewTodoDeleted extends TodosOverviewEvent {
  const TodosOverviewTodoDeleted(this.todo);

  final Todo todo;

  @override
  List<Object> get props => [todo];
}

class TodosOverviewToggleAllRequested extends TodosOverviewEvent {
  const TodosOverviewToggleAllRequested();
}

class TodosOverviewClearCompletedRequested extends TodosOverviewEvent {
  const TodosOverviewClearCompletedRequested();
}
