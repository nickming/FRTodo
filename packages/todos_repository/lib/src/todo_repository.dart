import 'package:todos_api/todo.dart';
import 'package:todos_api/todo_api.dart';

class TodoRepository {
  final TodoApi _todoApi;

  const TodoRepository({required TodoApi todoApi}) : _todoApi = todoApi;

  Stream<List<Todo>> getTodos() => _todoApi.getTodos();

  Future<void> saveTodo(Todo todo) => _todoApi.saveTodo(todo);

  Future<void> deleteTodo(String id) => _todoApi.deleteTodo(id);

  Future<int> completeAll(bool isCompleted) =>
      _todoApi.completeAll(isCompleted: isCompleted);

  Future<int> clearCompleted() => _todoApi.clearCompleted();
}
