// controllers/uds_controller.dart
// ---------------------------------------------------------------------------
// Manages all UDS diagnostic logic AND the UI state for the dashboard.
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uds/services/ble_service.dart';
import 'package:uds/models/uds_response.dart';
import 'package:uds/models/console_entry.dart';
import 'package:uds/utils/hex_formatter.dart';

class UdsController extends ChangeNotifier {
  final BleService _ble;
  UdsResponse? _lastResponse;
  bool _isLoading = false;
  String? _error;
  bool _writeSuccess = false;
  bool _isEcuOnline = false;
  bool _isInitialStatusFetched = false;
  int? _lastProcessedResponseId; // 🛡️ Deduplication tracking
  StreamSubscription<BluetoothConnectionState>? _bleStateSubscription;
  // ── RAPS DID Inventory (unchanged) ─────────────────────────────────────────
  static const Map<String, String> readOnlyDids = {
    "ECU Hardware Number": "F191",
    "ECU Part Number": "F187",
    "ECU Software Number": "F188",
    "VIN Number": "F190",
    "VCN Number": "F1A0",
    "PPN Number": "F1A1",
    "VCID Number": "F1A6",
    "Firmware Version": "220D",
    "ECU Serial Number": "F18C",
    "ECU Product Code": "F192",
    "Software Version": "220E",
    "System Voltage": "220F",
    "Axle 1 Angle": "2210",
    "Axle 5 Angle": "2211",
    "Axle 6 Angle": "2212",
    "Axle 5 Control": "2213",
    "Axle 6 Control": "2214",
    "Axle 5 Min Current Dir 1": "2215",
    "Axle 5 Max Current Dir 1": "2216",
    "Axle 5 Min Current Dir 2": "2217",
    "Axle 5 Max Current Dir 2": "2218",
    "Axle 6 Min Current Dir 1": "2219",
    "Axle 6 Max Current Dir 1": "221A",
    "Axle 6 Min Current Dir 2": "221B",
    "Axle 6 Max Current Dir 2": "221C",
  };

  static const Map<String, String> writableDids = {
    "VIN Number": "F190",
    "VCN Number": "F1A0",
    "PPN Number": "F1A1",
    "VCID Number": "F1A6",
    "Axle 1 Angle": "2210",
    "Axle 5 Angle": "2211",
    "Axle 6 Angle": "2212",
    "Axle 5 Control": "2213",
    "Axle 6 Control": "2214",
    "Axle 5 Min Current Dir 1": "2215",
    "Axle 5 Max Current Dir 1": "2216",
    "Axle 5 Min Current Dir 2": "2217",
    "Axle 5 Max Current Dir 2": "2218",
    "Axle 6 Min Current Dir 1": "2219",
    "Axle 6 Max Current Dir 1": "221A",
    "Axle 6 Min Current Dir 2": "221B",
    "Axle 6 Max Current Dir 2": "221C",
  };

  // ── UI state variables ─────────────────────────────────────────────────────
  String _selectedReadDid;
  String _selectedWriteDid;
  String _writeInputText = '';
  String currentInputMode = 'TEXT'; // Replaced _isTextMode bool!
  final List<ConsoleEntry> _consoleEntries = [];

  Timer? _timeoutTimer;

  // ── Constructor ────────────────────────────────────────────────────────────
  UdsController(this._ble)
    : _selectedReadDid = readOnlyDids.keys.first,
      _selectedWriteDid = writableDids.keys.first {
    _ble.responseStream.listen(_handleResponse);
    _ble.connectionStatusStream.listen(_handleConnectionStatus);

    // 📡 Listen for spontaneous disconnections (out of range, ECU off, etc.)
    _bleStateSubscription = _ble.connectionStateStream.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint("🚨 UdsController: BLE Disconnected unexpectedly!");
        _lastProcessedResponseId = null; // Reset deduplication
        _isInitialStatusFetched = false;
        notifyListeners(); // 🚀 This triggers UdsScreen to pop!
      }
    });
  }

  // ── Existing getters ───────────────────────────────────────────────────────
  UdsResponse? get lastResponse => _lastResponse;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _ble.isConnected;
  bool get isEcuOnline => _isEcuOnline;
  bool get writeSuccess => _writeSuccess;

  // ── UI state getters ───────────────────────────────────────────────────────
  String get selectedReadDid => _selectedReadDid;
  String get selectedWriteDid => _selectedWriteDid;
  String get writeInputText => _writeInputText;
  List<ConsoleEntry> get consoleEntries => List.unmodifiable(_consoleEntries);

  // ── Status Fetch ───────────────────────────────────────────────────────────
  Future<void> fetchStatus() async {
    if (isConnected && !_isInitialStatusFetched) {
      debugPrint("📡 Fetching initial system status...");
      _isInitialStatusFetched = true; // 🛡️ Prevent loops!
      await _ble.send({
        "command": "get_status",
        "id": DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // ── UI state setters ───────────────────────────────────────────────────────
  void setSelectedReadDid(String value) {
    _selectedReadDid = value;
    notifyListeners();
  }

  void setSelectedWriteDid(String didName) {
    _selectedWriteDid = didName;

    // 1. Get the actual Hex code for this DID name
    String hexCode = writableDids[didName] ?? "";

    // 2. Check if THAT Hex code is numeric
    bool isNumeric = isNumericDid(hexCode);

    // 3. Two-Way Auto-Switch Magic!
    if (isNumeric && currentInputMode == 'TEXT') {
      // If it's a math parameter, kick them to Decimal mode
      currentInputMode = 'DEC';
      _writeInputText = '';
    } else if (!isNumeric && currentInputMode != 'TEXT') {
      // If it's a text parameter (like VIN), kick them back to Text mode
      currentInputMode = 'TEXT';
      _writeInputText = '';
    }

    notifyListeners();
  }

  void setWriteInputText(String value) {
    _writeInputText = value;
    notifyListeners();
  }

  void setInputMode(String mode) {
    currentInputMode = mode;
    _writeInputText = '';
    notifyListeners();
  }

  // ── Console helpers ────────────────────────────────────────────────────────
  void _addConsoleEntry(ConsoleEntry entry) {
    _consoleEntries.add(entry);
    notifyListeners();
  }

  void clearConsole() {
    _consoleEntries.clear();
    notifyListeners();
  }

  // ── READ DID ───────────────────────────────────────────────────────────────
  Future<void> readDid(String did) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    String cleanDid = did.replaceAll(' ', '').toUpperCase();
    if (!cleanDid.startsWith('0x')) cleanDid = '0x$cleanDid';

    final cmd = {
      "command": "read_did",
      "did": cleanDid,
      "id": DateTime.now().millisecondsSinceEpoch,
    };

    _addConsoleEntry(
      ConsoleEntry(
        type: ConsoleEntryType.sent,
        message: 'READ $cleanDid',
        hexData: cleanDid,
      ),
    );

    await _ble.send(cmd);

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (_isLoading) {
        _isLoading = false;
        _error = "Timeout - No response from device";
        _addConsoleEntry(
          ConsoleEntry(
            type: ConsoleEntryType.error,
            message: 'Timeout – no response from ECU',
          ),
        );
        notifyListeners();
      }
    });
  }

  // ── WRITE DID (UPDATED FOR DEC MODE) ───────────────────────────────────────
  Future<void> writeDid(String did, String value) async {
    _isLoading = true;
    _writeSuccess = false;
    _error = null;
    notifyListeners();

    String cleanDid = did.replaceAll(' ', '').toUpperCase();
    if (!cleanDid.startsWith('0x')) {
      cleanDid = '0x$cleanDid';
    }

    int requiredLength = getRequiredLength(
      cleanDid,
    ); // Ensure your getRequiredLength is defined below this!

    // 🛑 DEC TO HEX CONVERSION MAGIC 🛑
    String dataToFormat = value;
    bool formattingAsText = (currentInputMode == 'TEXT');

    if (currentInputMode == 'DEC') {
      if (value.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      try {
        int numericValue = int.parse(value);
        int requiredHexChars = requiredLength > 0
            ? requiredLength * 2
            : 4; // Default to 4 chars (2 bytes) if unknown
        dataToFormat = numericValue
            .toRadixString(16)
            .padLeft(requiredHexChars, '0');
        formattingAsText = false; // Send the converted Hex to the formatter
      } catch (e) {
        _error = "Invalid Decimal Number";
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    // Now format it safely!
    String formattedData = _formatDataForWrite(
      dataToFormat,
      formattingAsText,
      requiredLength,
    );

    final cmd = {
      "command": "write_did",
      "did": cleanDid,
      "data": formattedData,
      "id": DateTime.now().millisecondsSinceEpoch,
    };

    _addConsoleEntry(
      ConsoleEntry(
        type: ConsoleEntryType.sent,
        message: 'WRITE $cleanDid',
        hexData: formattedData,
        asciiValue: currentInputMode == 'TEXT'
            ? value
            : null, // Only show ascii if it was actual text
      ),
    );

    await _ble.send(cmd);

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (_isLoading) {
        _isLoading = false;
        _error = "Write timeout – no response from device";
        _addConsoleEntry(
          ConsoleEntry(
            type: ConsoleEntryType.error,
            message: 'Write timeout – no response from ECU',
          ),
        );
        notifyListeners();
      }
    });
  }

  // ── Format data for write (Unchanged from your fix) ────────────────────────
  String _formatDataForWrite(
    String value,
    bool isTextMode,
    int requiredLength,
  ) {
    List<int> bytes;

    if (isTextMode) {
      bytes = utf8.encode(value).toList();
      if (bytes.length < requiredLength) {
        while (bytes.length < requiredLength) {
          bytes.add(0x20);
        }
      } else if (bytes.length > requiredLength) {
        bytes = bytes.sublist(0, requiredLength);
      }
    } else {
      String hex = value.replaceAll(' ', '').replaceAll('0x', '');
      bytes = [];
      for (int i = 0; i < hex.length; i += 2) {
        if (i + 2 <= hex.length) {
          String byteStr = hex.substring(i, i + 2);
          bytes.add(int.parse(byteStr, radix: 16));
        }
      }
      if (bytes.length < requiredLength) {
        while (bytes.length < requiredLength) {
          bytes.add(0x00);
        }
      } else if (bytes.length > requiredLength) {
        bytes = bytes.sublist(0, requiredLength);
      }
    }

    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('')
        .toUpperCase();
  }

  // ── Connection Status handler ──────────────────────────────────────────────
  void _handleConnectionStatus(Map<String, dynamic> data) {
    debugPrint("🔌 UdsController received Status: $data");
    _isEcuOnline = data['success'] == true;
    if (!_isEcuOnline) {
      _error = data['message'] ?? "ECU Offline";
    } else {
      _error = null;
    }
    notifyListeners();
  }

  // ── Response handler (Unchanged) ───────────────────────────────────────────
  void _handleResponse(Map<String, dynamic> data) {
    debugPrint("✅✅✅ LISTENER TRIGGERED! ✅✅✅");
    debugPrint("🧠 UdsController Processing: $data");

    // 🛡️ Deduplication Lock
    final int? currentId = data['id'];
    if (currentId != null && currentId == _lastProcessedResponseId) {
      debugPrint("⏭️ Skipping duplicate response ID: $currentId");
      return;
    }
    _lastProcessedResponseId = currentId;

    if (data.containsKey('success')) {
      _timeoutTimer?.cancel();
      try {
        _lastResponse = UdsResponse.fromJson(data);
        if (_lastResponse?.success == true) {
          _error = null;
          _isEcuOnline =
              true; // 🟢 If we got a successful response, ECU is ONLINE
          _writeSuccess = data['command'] != 'read_did';
          _addConsoleEntry(
            ConsoleEntry(
              type: ConsoleEntryType.success,
              message: _lastResponse?.did != null
                  ? 'Response DID ${_lastResponse!.did}'
                  : 'Success',
              hexData: _lastResponse?.data?.toString(),
              asciiValue: _lastResponse?.value,
            ),
          );
        } else {
          _error = _lastResponse?.error ?? "ECU Negative Response";
          _addConsoleEntry(
            ConsoleEntry(
              type: ConsoleEntryType.error,
              message: _error ?? 'ECU Negative Response',
              hexData: _lastResponse?.raw,
            ),
          );
        }
      } catch (e) {
        _error = "Parse Error: $e";
        _addConsoleEntry(
          ConsoleEntry(
            type: ConsoleEntryType.error,
            message: 'Parse error: $e',
          ),
        );
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      debugPrint("⚠️ Ignoring command echo: ${data['command']}");
      // 🛡️ CRITICAL: Even if it's an echo, if we are loading, we might want to keep waiting
      // or stop. But usually an echo means the message went through.
      // We'll keep isLoading = true until a 'success' field arrives.
    }
  }

  // ── Security access / unlock (Unchanged) ───────────────────────────────────
  Future<void> unlock() async {
    _isLoading = true;
    notifyListeners();
    await _ble.send({
      "command": "security_access",
      "id": DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> shutdownConnection() async {
    debugPrint("🚀 App closing/backgrounding: Shutting down UDS and BLE...");
    _isInitialStatusFetched = false; // Reset for next connect
    await _ble.disconnectAll();
    notifyListeners();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _bleStateSubscription?.cancel();
    super.dispose();
  }

  // PUT YOUR getRequiredLength(String did) FUNCTION HERE!
}
