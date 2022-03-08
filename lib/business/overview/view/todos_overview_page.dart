
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frtodo/business/edit/edit_todo.dart';
import 'package:frtodo/business/overview/bloc/todos_overview_bloc.dart';
import 'package:frtodo/business/overview/widgets/todo_list_tile.dart';
import 'package:frtodo/business/overview/widgets/todos_overview_filter_button.dart';
import 'package:frtodo/business/overview/widgets/todos_overview_options_button.dart';
import 'package:frtodo/l10n/i10n.dart';
import 'package:todos_repository/todo_repository.dart';

class TodoOverviewPage extends StatelessWidget {
  const TodoOverviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodosOverviewBloc(
        todoRepository: context.read<TodoRepository>(),
      )..add(const TodoOverviewSubscriptionRequested()),
      child: const TodoOverviewView(),
    );
  }
}

class TodoOverviewView extends StatelessWidget {
  const TodoOverviewView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
        appBar: AppBar(
          title: Text(l10n.todosOverviewAppBarTitle),
          actions: const [
            TodosOverviewFilterButton(),
            TodosOverviewOptionsButton()
          ],
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<TodosOverviewBloc, TodosOverviewState>(
                listenWhen: (previous, current) =>
                    previous.status != current.status,
                listener: (context, state) {
                  if (state.status == TodosOverviewStatus.failure) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                          content: Text(l10n.todosOverviewErrorSnackbarText)));
                  }
                }),
            BlocListener<TodosOverviewBloc, TodosOverviewState>(
                listenWhen: (previous, current) =>
                    previous.lastDeletedTodo != current.lastDeletedTodo &&
                    current.lastDeletedTodo != null,
                listener: (context, state) {
                  final deletedTodo = state.lastDeletedTodo;
                  final messenger = ScaffoldMessenger.of(context);

                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(l10n.todosOverviewTodoDeletedSnackbarText(
                          deletedTodo!.title)),
                      action: SnackBarAction(
                          label: l10n.todosOverviewUndoDeletionButtonText,
                          onPressed: () {
                            messenger.hideCurrentSnackBar();
                            context.read<TodosOverviewBloc>().add(
                                const TodosOverviewUndoDeletionRequested());
                          }),
                    ));
                })
          ],
          child: BlocBuilder<TodosOverviewBloc, TodosOverviewState>(
            builder: (context, state) {
              if (state.todos.isEmpty) {
                if (state.status == TodosOverviewStatus.loading) {
                  return const Center(child: CupertinoActivityIndicator());
                } else if (state.status == TodosOverviewStatus.success) {
                  return const SizedBox();
                } else {
                  return Center(
                    child: Text(
                      l10n.todosOverviewEmptyText,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  );
                }
              }
              return CupertinoScrollbar(
                child: ListView.builder(
                    itemCount: state.filteredTodos.length,
                    itemBuilder: (context, index) {
                      final todo = state.filteredTodos.elementAt(index);
                      return TodoListTile(
                        todo: todo,
                        onToggleCompleted: (isCompleted) {
                          context.read<TodosOverviewBloc>().add(
                              TodosOverviewTodoCompletionToggled(
                                  todo: todo, isCompleted: isCompleted));
                        },
                        onDismissed: (_) {
                          context
                              .read<TodosOverviewBloc>()
                              .add(TodosOverviewTodoDeleted(todo));
                        },
                        onTap: () {
                          Navigator.of(context)
                              .push(EditTodoPage.route(initialTodo: todo));
                        },
                      );
                    }),
              );
            },
          ),
        ));
  }
}
