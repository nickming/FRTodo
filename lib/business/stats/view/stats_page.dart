import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frtodo/business/stats/bloc/stats_bloc.dart';
import 'package:frtodo/l10n/i10n.dart';
import 'package:todos_repository/todo_repository.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatsBloc(
        todoRepository: context.read<TodoRepository>(),
      )..add(const StatsSubscriptionRequested()),
      child: const StatsView(),
    );
  }
}

class StatsView extends StatelessWidget {
  const StatsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.select((StatsBloc bloc) => bloc.state);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsAppBarTitle),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListTile(
            key: const Key('statsView_completed_todo_listTile'),
            title: Text(l10n.statsCompletedTodoCountLabel),
            leading: const Icon(Icons.check_rounded),
            trailing: Text(
              '${state.completedTodos}',
              style: textTheme.headline5,
            ),
          ),
          ListTile(
            key: const Key('statsView_activeTodos_listTile'),
            title: Text(l10n.statsActiveTodoCountLabel),
            leading: const Icon(Icons.radio_button_unchecked_rounded),
            trailing: Text(
              '${state.activeTodos}',
              style: textTheme.headline5,
            ),
          )
        ],
      ),
    );
  }
}
