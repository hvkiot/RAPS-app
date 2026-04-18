// models/ble_device.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

part 'ble_device.g.dart';

@JsonSerializable()
class BleDevice {
  final String name;
  final String id;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final BluetoothDevice? device; // 1. Make it nullable

  BleDevice({
    required this.name,
    required this.id,
    this.device, // 2. Remove 'required'
  });

  factory BleDevice.fromBluetoothDevice(BluetoothDevice device) {
    return BleDevice(
      name: device.advName.isNotEmpty ? device.advName : "Unknown Device",
      id: device.remoteId.toString(),
      device: device,
    );
  }

  factory BleDevice.fromJson(Map<String, dynamic> json) =>
      _$BleDeviceFromJson(json);
  Map<String, dynamic> toJson() => _$BleDeviceToJson(this);
}
