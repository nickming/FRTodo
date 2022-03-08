enum HomeTab { todos, stats }

class HomeState {
  final HomeTab tab;

  const HomeState({this.tab = HomeTab.todos});
}
