import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

part 'todo.g.dart';

//通过typedef简化负责的数据结构命名
typedef JsonMap = Map<String, dynamic>;

@immutable
//通过注解自动生成转换json方法并通过part关键字隔离自动生成的代码
//1. 添加注解并指定生成文件名
//3. 执行flutter pub run build_runner build
@JsonSerializable()
class Todo extends Equatable {
  final String id;
  final String title;
  final String description;
  @JsonKey(name: "is_completed")
  final bool isCompleted;
  @JsonKey(name: "created_ts")
  final num createdTs;

  Todo(
      {String? id,
      num? createdTs,
      required this.title,
      this.description = "",
      this.isCompleted = false})
      : id = id ?? const Uuid().v4(),
        createdTs = createdTs ?? DateTime.now().millisecondsSinceEpoch;

  Todo copyWith(
      {String? id,
      String? title,
      String? description,
      bool? isCompleted,
      num? createdTs}) {
    return Todo(
        title: title ?? this.title,
        id: id ?? this.id,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        createdTs: createdTs ?? this.createdTs);
  }

  static Todo fromJson(JsonMap json) => _$TodoFromJson(json);

  JsonMap toJson() => _$TodoToJson(this);

  @override
  List<Object?> get props => [id, title, description, isCompleted];
}
