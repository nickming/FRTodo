import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_services_binding/flutter_services_binding.dart';
import 'package:frtodo/business/home/home.dart';
import 'package:frtodo/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:local_storage_todos_api/todo_rust_storage_api.dart';
import 'package:local_storage_todos_api/todo_storage_api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todos_repository/todo_repository.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    log('onChange(${bloc.runtimeType},$change)');
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType},$error,$stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> main() async {
  FlutterServicesBinding.ensureInitialized();
  boostrap();
}

Future<TodoRepository> _todoRepository() async {
  Directory directory = await getApplicationDocumentsDirectory();
  File databaseFile = File('${directory.path}/todos.db');
  bool isExist = await databaseFile.exists();
  if (!isExist) {
    await databaseFile.create();
  }
  log("database file path is:${databaseFile.path}");
  // final rustApi = RustStorageTodoApi(databasePath: databaseFile.path);

  final sharePreferenceApi =
      LocalStorageTodoApi(plugin: await SharedPreferences.getInstance());

  return TodoRepository(todoApi: sharePreferenceApi);
}

void boostrap() {
  FlutterError.onError = (detail) {
    log(detail.exceptionAsString(), stackTrace: detail.stack);
  };
  runZonedGuarded(() async {
    BlocOverrides.runZoned(() async {
      final repo = await _todoRepository();
      runApp(MyApp(
        todoRepository: repo,
      ));
    }, blocObserver: AppBlocObserver());
  }, (error, stackTrace) => log(error.toString(), stackTrace: stackTrace));
}

class MyApp extends StatelessWidget {
  final TodoRepository todoRepository;

  const MyApp({Key? key, required this.todoRepository}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
        value: todoRepository,
        child: MaterialApp(
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dart,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TodoHomePage(),
        ));
  }
}
