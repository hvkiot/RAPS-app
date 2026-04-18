// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uds_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UdsCommand _$UdsCommandFromJson(Map<String, dynamic> json) => UdsCommand(
  command: json['command'] as String,
  did: json['did'] as String?,
  data: json['data'] as String?,
  id: (json['id'] as num).toInt(),
);

Map<String, dynamic> _$UdsCommandToJson(UdsCommand instance) =>
    <String, dynamic>{
      'command': instance.command,
      'did': instance.did,
      'data': instance.data,
      'id': instance.id,
    };
