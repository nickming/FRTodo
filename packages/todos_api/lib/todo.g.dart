// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Todo _$TodoFromJson(Map<String, dynamic> json) => Todo(
      id: json['id'] as String?,
      createdTs: json['created_ts'] as num?,
      title: json['title'] as String,
      description: json['description'] as String? ?? "",
      isCompleted: json['is_completed'] as bool? ?? false,
    );

Map<String, dynamic> _$TodoToJson(Todo instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'is_completed': instance.isCompleted,
      'created_ts': instance.createdTs,
    };
