// views/widgets/write_tab.dart
// ---------------------------------------------------------------------------
// The WRITE tab of the UDS dashboard. Contains a DID dropdown, text/hex mode
// toggle, value input field, an Expanded LogConsole, and a Write button.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uds/controllers/uds_controller.dart';
import 'package:uds/utils/hex_formatter.dart';
import 'package:uds/views/widgets/log_console.dart';

class WriteTab extends StatefulWidget {
  const WriteTab({super.key});

  @override
  State<WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends State<WriteTab> {
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  /// Byte-length required for the currently selected writable DID.
  int _requiredLength(UdsController uds) {
    final hex = UdsController.writableDids[uds.selectedWriteDid];
    if (hex == null) return 0;
    return getRequiredLength(hex);
  }

  @override
  Widget build(BuildContext context) {
    final uds = context.watch<UdsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reqLen = _requiredLength(uds);
    final selectedHex = UdsController.writableDids[uds.selectedWriteDid] ?? "";
    bool isNumeric = isNumericDid(selectedHex);
    final String hexDid =
        UdsController.writableDids[uds.selectedWriteDid] ?? '';
    final bool isCurrentLimitDid = [
      "2215",
      "2216",
      "2217",
      "2218",
      "2219",
      "221A",
      "221B",
      "221C",
    ].contains(hexDid);
    final isAngleDid = ["2210", "2211", "2212"].contains(hexDid);
    final bool isAngleValid =
        !isAngleDid || (int.tryParse(_valueController.text) == 0);
    bool canWrite = false;
    String? lengthError;

    if (uds.writeInputText.isNotEmpty) {
      if (uds.currentInputMode == 'DEC') {
        canWrite = true; // Decimals can be any length (backend handles it)
      } else {
        int requiredChars = uds.currentInputMode == 'TEXT'
            ? reqLen
            : reqLen * 2;
        if (uds.writeInputText.length < requiredChars) {
          lengthError =
              'Must be exactly $requiredChars characters (Current: ${uds.writeInputText.length})';
        } else {
          canWrite = true; // Length is perfectly matched!
        }
      }
    }

    return AbsorbPointer(
      absorbing: uds.isLoading,
      child: Column(
        children: [
          // ── DID dropdown + mode toggle + input field inside a Card ─────
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Text(
                    'TARGET IDENTIFIER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: uds.selectedWriteDid,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF1A1A1A)
                        : Colors.white,
                    items: UdsController.writableDids.keys.map((name) {
                      final hex = UdsController.writableDids[name]!;
                      return DropdownMenuItem(
                        value: name,
                        child: Text('$hex – $name'),
                      );
                    }).toList(),
                    onChanged: uds.isLoading
                        ? null
                        : (val) {
                            if (val != null) {
                              uds.setSelectedWriteDid(val);
                              uds.resetWriteStatus();
                              // 🧹 Reset controller state to avoid "Range start out of text" errors
                              _valueController.value = TextEditingValue.empty;
                            }
                          },
                  ),
                  const SizedBox(height: 20),

                  // Text / Hex toggle
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.comfortable,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      segments: [
                        ButtonSegment(
                          value: 'TEXT',
                          label: const Text(
                            'TEXT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          enabled: !isNumeric,
                        ),
                        const ButtonSegment(
                          value: 'HEX',
                          label: Text(
                            'HEX',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ButtonSegment(
                          value: 'DEC',
                          label: const Text(
                            'DEC',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          enabled: isNumeric,
                        ),
                      ],
                      selected: {uds.currentInputMode},
                      onSelectionChanged: (sel) {
                        uds.setInputMode(sel.first);
                        _valueController.clear();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Value input
                  TextField(
                    controller: _valueController,
                    keyboardType: uds.currentInputMode == 'DEC'
                        ? TextInputType.number
                        : TextInputType.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      labelText: uds.currentInputMode == 'TEXT'
                          ? 'Enter Text (max $reqLen chars)'
                          : uds.currentInputMode == 'DEC'
                          ? 'Enter Decimal Number'
                          : 'Enter HEX (max ${reqLen * 2} chars)',
                      hintText: uds.currentInputMode == 'TEXT'
                          ? 'e.g. CCM1100S-123'
                          : uds.currentInputMode == 'DEC'
                          ? 'e.g. 1000'
                          : 'e.g. 03E8',
                      errorText: () {
                        // 1. Check for Current Limit DIDs (100-2500)
                        if (isCurrentLimitDid &&
                            uds.currentInputMode == 'DEC' &&
                            _valueController.text.isNotEmpty) {
                          if (!uds.isRangeValid) {
                            return 'Value must be between 100 and 2500';
                          }
                        }

                        // 2. Check for Angle DIDs (Must be 0)

                        if (isAngleDid &&
                            uds.currentInputMode == 'DEC' &&
                            _valueController.text.isNotEmpty) {
                          final val = int.tryParse(_valueController.text);
                          if (val != null && val != 0) {
                            return "Calibration requires 0"; // More professional than "Not Allow"
                          }
                        }

                        return lengthError; // errors
                      }(),
                      helperText:
                          (isCurrentLimitDid && uds.currentInputMode == 'DEC')
                          ? 'Range: 100 - 2500'
                          : (uds.currentInputMode == 'DEC')
                          ? 'Calibration: Set to 0 to zero-point the axle'
                          : null,
                      helperStyle: TextStyle(
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLength: uds.currentInputMode == 'TEXT'
                        ? reqLen
                        : uds.currentInputMode == 'DEC'
                        ? null
                        : reqLen * 2,
                    inputFormatters: [
                      if (uds.currentInputMode == 'HEX') HexInputFormatter(),
                      if (uds.currentInputMode == 'DEC')
                        FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (val) {
                      uds.setWriteInputText(val);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Console (Expanded) ────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LogConsole(entries: uds.consoleEntries),
            ),
          ),

          // ── Write button + status LED ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: theme.colorScheme.error.withValues(
                    alpha: 0.12,
                  ),
                  disabledForegroundColor: theme.colorScheme.onSurface
                      .withValues(alpha: 0.38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: uds.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_rounded, size: 24),
                label: Text(
                  uds.isLoading
                      ? 'WRITING...'
                      : uds.isCalibrationDID(_valueController.text)
                      ? 'CALIBRATE ZERO'
                      : 'WRITE DATA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                onPressed:
                    (uds.isLoading ||
                        !canWrite ||
                        !uds.isRangeValid ||
                        uds.lastWrittenDid ==
                            '0x${UdsController.writableDids[uds.selectedWriteDid]}' ||
                        !isAngleValid)
                    ? null // This disables the button
                    : () {
                        print(
                          (isCurrentLimitDid && // Only show error for Current DIDs
                              uds.currentInputMode == 'DEC' &&
                              _valueController.text.isNotEmpty &&
                              !uds.isRangeValid),
                        );
                        FocusManager.instance.primaryFocus?.unfocus();
                        // This executes the write
                        final hexDid =
                            UdsController.writableDids[uds.selectedWriteDid];
                        if (hexDid != null) {
                          String valueToSend = uds.isCalibrationDID(hexDid)
                              ? "0"
                              : _valueController.text;

                          uds.writeDid(hexDid, valueToSend);
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing "WRITE OK" LED indicator ─────────────────────────────────────────
class _WriteOkLed extends StatefulWidget {
  final bool isActive;
  const _WriteOkLed({required this.isActive});

  @override
  State<_WriteOkLed> createState() => _WriteOkLedState();
}

class _WriteOkLedState extends State<_WriteOkLed>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green = theme.colorScheme.secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.isActive
            ? FadeTransition(
                opacity: _ctrl,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: green,
                    boxShadow: [
                      BoxShadow(
                        color: green.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.dividerColor,
                ),
              ),
        const SizedBox(width: 8),
        Text(
          'WRITE OK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}
