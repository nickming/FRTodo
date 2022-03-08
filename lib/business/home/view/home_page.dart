
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frtodo/business/edit/edit_todo.dart';
import 'package:frtodo/business/home/cubit/home_cubit.dart';
import 'package:frtodo/business/home/cubit/home_state.dart';
import 'package:frtodo/business/overview/view/todos_overview_page.dart';
import 'package:frtodo/business/stats/view/stats_page.dart';

class TodoHomePage extends StatelessWidget {
  const TodoHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => HomeCubit(), child: const HomeView());
  }
}

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //可以通过BlocBuilder获取也可以通过context select获取对应的cubit
    //BlocBuilder适合在组件闭包中实现局部刷新时使用，select适合单独组件使用或者整个组件依赖state变化
    final selectedTab = context.select((HomeCubit cubit) => cubit.state.tab);
    return Scaffold(
      body: IndexedStack(
        index: selectedTab.index,
        children: const [TodoOverviewPage(), StatsPage()],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_rounded),
        onPressed: () {
          Navigator.of(context).push(EditTodoPage.route());
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _HomeTabButton(
                groupValue: selectedTab,
                value: HomeTab.todos,
                icon: const Icon(Icons.list_rounded)),
            _HomeTabButton(
                groupValue: selectedTab,
                value: HomeTab.stats,
                icon: const Icon(Icons.show_chart_rounded))
          ],
        ),
      ),
    );
  }
}

class _HomeTabButton extends StatelessWidget {
  final HomeTab groupValue;
  final HomeTab value;
  final Widget icon;

  const _HomeTabButton(
      {Key? key,
      required this.groupValue,
      required this.value,
      required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () => context.read<HomeCubit>().setTab(value),
        iconSize: 32,
        color: groupValue != value
            ? null
            : Theme.of(context).colorScheme.secondary,
        icon: icon);
  }
}
