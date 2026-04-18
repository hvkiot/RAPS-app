// models/uds_command.dart
import 'package:json_annotation/json_annotation.dart';

part 'uds_command.g.dart';

@JsonSerializable()
class UdsCommand {
  @JsonKey(name: 'command')
  final String command;

  @JsonKey(name: 'did')
  final String? did;

  @JsonKey(name: 'data')
  final String? data;

  @JsonKey(name: 'id')
  final int id;

  UdsCommand({required this.command, this.did, this.data, required this.id});

  factory UdsCommand.fromJson(Map<String, dynamic> json) =>
      _$UdsCommandFromJson(json);

  Map<String, dynamic> toJson() => _$UdsCommandToJson(this);
}
