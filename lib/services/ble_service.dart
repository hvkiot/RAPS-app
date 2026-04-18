import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uds/config/app_config.dart';

class BleService {
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  // Stream Controllers
  final _responseController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();

  Stream<Map<String, dynamic>> get responseStream => _responseController.stream;
  Stream<Map<String, dynamic>> get connectionStatusStream =>
      _connectionStatusController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  bool get isConnected => _characteristic != null;

  Future<void> connectAndDiscover(BluetoothDevice device) async {
    _connectionSubscription = device.connectionState.listen((state) {
      debugPrint("Connection state: $state");
      _connectionStateController.add(state); // 📡 Broadcast to app
      if (state == BluetoothConnectionState.disconnected) {
        _characteristic = null;
        _notificationSubscription?.cancel();
      }
    });

    await device.connect(timeout: AppConfig.bleTimeout, autoConnect: false);

    try {
      int mtu = await device.requestMtu(512);
      debugPrint("MTU negotiated: $mtu");
    } catch (e) {
      debugPrint("MTU negotiation failed: $e");
    }

    debugPrint("Discovering services...");
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.uuid.toString().toUpperCase() ==
            AppConfig.characteristicUuid.toUpperCase()) {
          _characteristic = char;
          debugPrint("✅ Found characteristic: ${char.uuid}");
          debugPrint("   Properties: ${char.properties}");

          await _setupNotifications(char);
          return;
        }
      }
    }

    throw Exception("Target characteristic not found");
  }

  Future<void> _setupNotifications(BluetoothCharacteristic char) async {
    await _notificationSubscription?.cancel();
    // _lastProcessedValue = null; // Reset on new connection

    if (char.properties.notify || char.properties.indicate) {
      // 1. LISTEN FIRST!
      _notificationSubscription = char.onValueReceived.listen((value) {
        if (value.isEmpty) return;

        debugPrint('🔔 NOTIFICATION RECEIVED!');
        debugPrint('Value: $value');

        _handleReceivedData(value);
      });

      // 2. NOW enable indications on the hardware
      await char.setNotifyValue(true);
      debugPrint('✅ Notifications/Indications enabled');
    }
  }

  void _handleReceivedData(List<int> value) {
    try {
      final jsonString = String.fromCharCodes(value).trim();
      debugPrint('JSON: $jsonString');

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('✅ BLE PARSED: $jsonData');

      // Check if this is a connection status update
      if (jsonData.containsKey('type') &&
          jsonData['type'] == 'connection_status') {
        debugPrint('🔌 CONNECTION STATUS: ${jsonData['status']}');
        _connectionStatusController.add(jsonData);
        return;
      }

      if (jsonData.containsKey('success')) {
        _responseController.add(jsonData);
      } else {
        debugPrint('⚠️ Ignoring echo: ${jsonData['command']}');
      }
    } catch (e) {
      debugPrint('❌ Raw parsing failed: $e');
    }
  }

  Future<void> send(Map<String, dynamic> data) async {
    // _jsonBuffer.clear(); // 🛑 Clear stale data before sending new command
    if (_characteristic == null) {
      throw Exception("Characteristic not found");
    }

    final jsonStr = jsonEncode(data);
    final bytes = utf8.encode(jsonStr);

    debugPrint('📤 SENDING: $jsonStr');
    await _characteristic!.write(bytes);
    debugPrint('✅ Sent successfully');
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      debugPrint('🔄 Initiating manual pull...');
      await _characteristic!.read();
    } catch (e) {
      debugPrint('❌ Manual pull failed: $e');
    }
  }

  Future<void> disconnect(BluetoothDevice device) async {
    await _notificationSubscription?.cancel();
    await _connectionSubscription?.cancel();

    if (_characteristic != null) {
      try {
        await _characteristic!.setNotifyValue(false);
      } catch (e) {
        debugPrint('❌ Failed to disable notifications: $e');
      }
    }

    await device.disconnect();
    _characteristic = null;
    debugPrint("Disconnected");
  }

  Future<void> disconnectAll() async {
    try {
      List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        await device.disconnect();
      }

      // 🛑 CRITICAL: Explicitly set this to null so isConnected returns false
      _characteristic = null;

      debugPrint("✅ All BLE connections severed.");
    } catch (e) {
      debugPrint("❌ Error during disconnectAll: $e");
    }
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _responseController.close();
    _connectionStatusController.close();
  }
}
