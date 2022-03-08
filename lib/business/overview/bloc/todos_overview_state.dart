part of 'todos_overview_bloc.dart';

enum TodosOverviewStatus { initial, loading, success, failure }

class TodosOverviewState extends Equatable {
  final List<Todo> todos;
  final Todo? lastDeletedTodo;
  final TodosViewFilter filter;
  final TodosOverviewStatus status;

  const TodosOverviewState(
      {this.status = TodosOverviewStatus.initial,
      this.todos = const [],
      this.lastDeletedTodo,
      this.filter = TodosViewFilter.all});

  Iterable<Todo> get filteredTodos => filter.applyAll(todos);

  TodosOverviewState copyWith({
    TodosOverviewStatus Function()? status,
    List<Todo> Function()? todos,
    TodosViewFilter Function()? filter,
    Todo? Function()? lastDeletedTodo,
  }) {
    return TodosOverviewState(
      status: status != null ? status() : this.status,
      todos: todos != null ? todos() : this.todos,
      filter: filter != null ? filter() : this.filter,
      lastDeletedTodo:
          lastDeletedTodo != null ? lastDeletedTodo() : this.lastDeletedTodo,
    );
  }

  @override
  List<Object?> get props => [status, todos, filter, lastDeletedTodo];
}
