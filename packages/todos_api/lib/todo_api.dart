import 'package:todos_api/todo.dart';

abstract class TodoApi {
  const TodoApi();

  // 为什么不用Future？
  // 1. 如果用Future则每一次CRUD操作都需要查询整个列表返回，每次更新全量状态返回
  // 2. Future是一次性交付数据，不能做到更新通知
  // 3. 采用Stream则能做到每次对数据监听都进行实时通知更新
  Stream<List<Todo>> getTodos();

  Future<void> saveTodo(Todo todo);

  Future<void> deleteTodo(String id);

  Future<int> clearCompleted();

  Future<int> completeAll({required bool isCompleted});
}

class TodoNotFoundException implements Exception {}
