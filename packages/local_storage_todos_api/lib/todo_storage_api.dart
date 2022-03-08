import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todos_api/todo.dart';
import 'package:todos_api/todo_api.dart';

class LocalStorageTodoApi extends TodoApi {
  final SharedPreferences _plugin;

  final _todoStreamController = BehaviorSubject<List<Todo>>.seeded(const []);

  @visibleForTesting
  static const kTodosCollectionKey = '__todos_collection_key__';

  LocalStorageTodoApi({required SharedPreferences plugin}) : _plugin = plugin {
    _init();
  }

  String? _getValue(String key) => _plugin.getString(key);

  Future<bool> _saveValue(String key, String value) =>
      _plugin.setString(key, value);

  Future<bool> _updateLocalTodos(List<Todo> todos) async {
    _todoStreamController.add(todos);
    return await _saveValue(kTodosCollectionKey, json.encode(todos));
  }

  List<Todo> _getCurrentTodos() => [..._todoStreamController.value];

  void _init() {
    final todoJson = _getValue(kTodosCollectionKey);
    if (todoJson != null) {
      final todos = List<Map>.from(json.decode(todoJson) as List)
          .map((e) => Todo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _todoStreamController.add(todos);
    } else {
      _todoStreamController.add(const []);
    }
  }

  @override
  Future<int> clearCompleted() async {
    final todos = [..._todoStreamController.value];
    final completedTodosAmount =
        todos.where((element) => element.isCompleted).length;
    todos.removeWhere((element) => element.isCompleted);
    await _updateLocalTodos(todos);
    return completedTodosAmount;
  }

  @override
  Future<int> completeAll({required bool isCompleted}) async {
    final todos = [..._todoStreamController.value];
    final changeTodosAmount =
        todos.where((element) => element.isCompleted != isCompleted).length;

    //因为state按照单一职责不允许更改状态，只能通过copy实现，类似kotlin中的data结构
    //[]里面可以写for循环来使用
    final newTodos =
        todos.map((e) => e.copyWith(isCompleted: isCompleted)).toList();
    // final newTodos = [
    //   for (final todo in todos) todo.copyWith(isCompleted: isCompleted)
    // ];
    await _updateLocalTodos(newTodos);
    return changeTodosAmount;
  }

  @override
  Future<void> deleteTodo(String id) {
    final todos = _getCurrentTodos();
    final deleteIndex = todos.indexWhere((element) => element.id == id);
    if (deleteIndex >= 0) {
      todos.removeAt(deleteIndex);
      return _updateLocalTodos(todos);
    }
    throw TodoNotFoundException();
  }

  @override
  Stream<List<Todo>> getTodos() => _todoStreamController.asBroadcastStream();

  @override
  Future<void> saveTodo(Todo todo) {
    final todos = _getCurrentTodos();
    final todoIndex = todos.indexWhere((element) => element.id == todo.id);
    if (todoIndex >= 0) {
      todos[todoIndex] = todo;
    } else {
      todos.add(todo);
    }
    return _updateLocalTodos(todos);
  }
}