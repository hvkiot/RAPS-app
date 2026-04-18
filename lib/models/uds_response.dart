import 'package:json_annotation/json_annotation.dart';

part 'uds_response.g.dart';

@JsonSerializable()
class UdsResponse {
  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'data')
  final String? data;

  @JsonKey(name: 'error')
  final String? error;

  @JsonKey(name: 'did')
  final String? did;

  @JsonKey(name: 'value')
  final String? value;

  @JsonKey(name: 'raw')
  final String? raw;

  UdsResponse({
    required this.success,
    required this.id,
    this.data,
    this.error,
    this.did,
    this.value,
    this.raw,
  });

  factory UdsResponse.fromJson(Map<String, dynamic> json) =>
      _$UdsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UdsResponseToJson(this);

  @override
  String toString() {
    return 'UdsResponse(success: $success, id: $id, data: $data, error: $error, did: $did, value: $value, raw: $raw)';
  }
}
