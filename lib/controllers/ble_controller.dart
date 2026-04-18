// controllers/ble_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uds/models/ble_device.dart';
import 'package:uds/services/ble_service.dart';
import 'package:uds/config/app_config.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

enum ConnectionStatus { disconnected, connecting, connected, error }

class BleController extends ChangeNotifier {
  final BleService bleService;

  List<BleDevice> _scannedDevices = [];
  bool _isScanning = false;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  BluetoothDevice? _connectedDevice;
  String? _errorMessage;

  // Track subscriptions to prevent memory leaks
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _adapterStateSubscription;
  StreamSubscription? _locationServiceSubscription;

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  bool _isLocationEnabled = true;
  bool _arePermissionsGranted = false;

  BleController(this.bleService) {
    _initListeners();
  }

  void _initListeners() {
    // 0. Initial Permission Check
    checkAndRequestPermissions();

    // 1. Monitor Bluetooth Adapter State
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });

    // 2. Monitor Location Service Status
    _checkLocationStatus();
    _locationServiceSubscription = geo.Geolocator.getServiceStatusStream()
        .listen((status) {
          _isLocationEnabled = (status == geo.ServiceStatus.enabled);
          notifyListeners();
        });
  }

  Future<void> _checkLocationStatus() async {
    _isLocationEnabled = await geo.Geolocator.isLocationServiceEnabled();
    notifyListeners();
  }

  Future<bool> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      // Logic provided by user: Check if device is Android 12 or newer
      // Note: We check bluetoothScan permission as a proxy for Android 12+ requirements
      final scanStatus = await Permission.bluetoothScan.status;

      if (scanStatus.isDenied || scanStatus.isPermanentlyDenied) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location, // Still good practice to request
        ].request();

        _arePermissionsGranted =
            statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
            statuses[Permission.bluetoothConnect] == PermissionStatus.granted;

        if (!_arePermissionsGranted) {
          debugPrint("❌ Android 12+ BLE Permissions Denied!");
        }
      } else {
        // For older devices or if already granted
        final locationStatus = await Permission.location.request();
        _arePermissionsGranted = locationStatus.isGranted;

        if (!_arePermissionsGranted) {
          debugPrint("❌ Legacy Location Permission Denied!");
        }
      }
    } else {
      // iOS / other platforms
      _arePermissionsGranted = true;
    }

    notifyListeners();
    return _arePermissionsGranted;
  }

  // Getters
  List<BleDevice> get scannedDevices => _scannedDevices;
  bool get isScanning => _isScanning;
  ConnectionStatus get status => _status;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get errorMessage => _errorMessage;
  BluetoothAdapterState get adapterState => _adapterState;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get arePermissionsGranted => _arePermissionsGranted;

  bool get isBluetoothOn => _adapterState == BluetoothAdapterState.on;

  // Actions
  Future<void> turnOnBluetooth() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      debugPrint("Could not turn on Bluetooth: $e");
    }
  }

  Future<void> openLocationSettings() async {
    await geo.Geolocator.openLocationSettings();
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    // Check permissions first
    if (!_arePermissionsGranted) {
      final granted = await checkAndRequestPermissions();
      if (!granted) {
        _errorMessage = "Permissions required to scan";
        notifyListeners();
        return;
      }
    }

    _scannedDevices.clear();
    _errorMessage = null;
    _isScanning = true;
    notifyListeners();

    try {
      // 1. Cancel previous subscription if it exists
      await _scanSubscription?.cancel();

      // 2. Start the scan
      await FlutterBluePlus.startScan(
        timeout: AppConfig.scanDuration,
        // Optional: Filter by Service UUID to only show your Pi
        withServices: [Guid(AppConfig.serviceUuid)],
      );

      // 3. Listen for results and filter duplicates
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        final List<BleDevice> tempDevices = [];
        for (var r in results) {
          // Only add if not already in list (check by remoteId/MAC)
          if (!tempDevices.any((d) => d.id == r.device.remoteId.toString())) {
            tempDevices.add(BleDevice.fromBluetoothDevice(r.device));
          }
        }
        _scannedDevices = tempDevices;
        notifyListeners();
      });

      // 4. Wait for timeout then stop
      await Future.delayed(AppConfig.scanDuration);
      await stopScan();
    } catch (e) {
      _errorMessage = "Scan error: $e";
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connect(BleDevice bleDevice) async {
    // Safety check: Don't connect to null hardware handle
    if (bleDevice.device == null) {
      _errorMessage = "Hardware handle missing";
      notifyListeners();
      return;
    }

    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Stop scan before connecting (Prevents Status 133)
      await stopScan();

      // 2. Short delay for Android Bluetooth stack to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Perform the connection
      await bleService.connectAndDiscover(bleDevice.device!);

      _connectedDevice = bleDevice.device;
      _status = ConnectionStatus.connected;

      // 4. Listen for accidental disconnection
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = bleDevice.device!.connectionState.listen((
        state,
      ) {
        if (state == BluetoothConnectionState.disconnected) {
          _status = ConnectionStatus.disconnected;
          _connectedDevice = null;
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = "Connection error: $e";
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await bleService.disconnect(_connectedDevice!);
      await _connectionStateSubscription?.cancel();
      _connectedDevice = null;
      _status = ConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _locationServiceSubscription?.cancel();
    super.dispose();
  }
}
