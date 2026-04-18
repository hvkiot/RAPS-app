// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uds_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UdsResponse _$UdsResponseFromJson(Map<String, dynamic> json) => UdsResponse(
  success: json['success'] as bool,
  id: (json['id'] as num).toInt(),
  data: json['data'] as String?,
  error: json['error'] as String?,
  did: json['did'] as String?,
  value: json['value'] as String?,
  raw: json['raw'] as String?,
);

Map<String, dynamic> _$UdsResponseToJson(UdsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'id': instance.id,
      'data': instance.data,
      'error': instance.error,
      'did': instance.did,
      'value': instance.value,
      'raw': instance.raw,
    };
