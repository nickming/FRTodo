import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:local_storage_todos_api/todo_bridge_generated.dart';
import 'package:rxdart/rxdart.dart';
import 'package:todos_api/todo.dart';
import 'package:todos_api/todo_api.dart';

const todo_lib_name = "rust_todo";
final path = Platform.isWindows ? '$todo_lib_name.dll' : 'lib$todo_lib_name.so';
DynamicLibrary dylib =
    Platform.isIOS ? DynamicLibrary.process() : Platform.isMacOS ? DynamicLibrary.executable() : DynamicLibrary.open(path);
late RustTodoImpl rustTodoImpl = RustTodoImpl(dylib);

class TodoResponse {
  String? error;
  int? changeRows;
  List<Todo>? data;

  TodoResponse.fromJson(String json) {
    final decoded = jsonDecode(json);
    error = decoded["error"];
    changeRows = decoded["change_rows"];
    try {
      final todos = decoded["data"] as List<dynamic>;
      data = todos.map((e) => Todo.fromJson(e)).toList();
    } catch (e) {
      data = null;
      log("parse todo response error:${e}");
    }
  }
}

class RustStorageTodoApi extends TodoApi {
  final _todoStreamController = BehaviorSubject<List<Todo>>.seeded(const []);

  RustStorageTodoApi({required String databasePath}) {
    _init(databasePath);
  }

  _init(String databasePath) async {
    rustTodoImpl.registerEventListener().listen((event) {
      log("receive event:$event");
    });
    await rustTodoImpl.initialize(path: databasePath);
    await _queryAllTodos();
  }

  Future<void> _queryAllTodos() async {
    final todoResult = await rustTodoImpl.queryAll();
    log("get todos result:${todoResult}");
    final allTodos = TodoResponse.fromJson(todoResult).data;
    if (allTodos != null) {
      _todoStreamController.add(allTodos);
    }
  }

  @override
  Future<int> clearCompleted() async {
    final result = await rustTodoImpl.clearCompleted();
    log("clearCompleted result:${result}");
    await _queryAllTodos();
    return TodoResponse.fromJson(result).changeRows ?? 0;
  }

  @override
  Future<int> completeAll({required bool isCompleted}) async {
    final result =
        await rustTodoImpl.completeAll(isCompletedValue: isCompleted);
    log("completeAll result:${result}");
    await _queryAllTodos();
    return TodoResponse.fromJson(result).changeRows ?? 0;
  }

  @override
  Future<void> deleteTodo(String id) async {
    final result = await rustTodoImpl.delete(todoId: id);
    log("delete todo result:${result}");
    await _queryAllTodos();
  }

  @override
  Stream<List<Todo>> getTodos() => _todoStreamController.asBroadcastStream();

  @override
  Future<void> saveTodo(Todo todo) async {
    final json = jsonEncode(todo);
    final result = await rustTodoImpl.save(todoData: json);
    await _queryAllTodos();
    log("save todo result:${result}");
  }
}
