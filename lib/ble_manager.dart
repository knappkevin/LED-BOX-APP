import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BleManager {
  static final BleManager _instance = BleManager._internal();
  factory BleManager() => _instance;
  BleManager._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  String? _lastDeviceId;

  static const String _nusServiceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String _nusRxCharUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  Stream<BluetoothConnectionState> get connectionState {
    if (_connectedDevice == null) {
      return Stream.value(BluetoothConnectionState.disconnected);
    }
    return _connectedDevice!.state;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lastDeviceId = prefs.getString('last_device_id');
  }

  Future<List<BluetoothDevice>> scanDevices({int timeout = 5}) async {
    final Set<BluetoothDevice> devices = {};
    StreamSubscription? sub;
    final completer = Completer<void>();

    sub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        devices.add(result.device);
      }
    });

    unawaited(
      FlutterBluePlus.startScan(timeout: Duration(seconds: timeout)).then(
        (_) => Future.delayed(
          Duration(seconds: timeout),
        ).then((_) => completer.complete()),
      ),
    );

    await completer.future.timeout(
      Duration(seconds: timeout + 2),
      onTimeout: () => null,
    );

    await sub.cancel();
    return devices.toList();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      final prefs = await SharedPreferences.getInstance();
      _lastDeviceId = device.remoteId.str;
      await prefs.setString('last_device_id', _lastDeviceId!);

      await _discoverServices();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    final services = await _connectedDevice!.discoverServices();
    print('Discovered ${services.length} services');

    // Look for Nordic UART Service first
    for (final service in services) {
      if (service.uuid.toString().toUpperCase() ==
          _nusServiceUuid.toUpperCase()) {
        print('Found Nordic UART Service');
        for (final char in service.characteristics) {
          if (char.uuid.toString().toUpperCase() ==
              _nusRxCharUuid.toUpperCase()) {
            _writeCharacteristic = char;
            print('Selected NUS RX characteristic: ${char.uuid}');
            return;
          }
        }
      }
    }

    // Fallback: first writable characteristic
    print('Nordic UART Service not found, using fallback');
    for (final service in services) {
      for (final char in service.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          _writeCharacteristic = char;
          print('Selected fallback characteristic: ${char.uuid}');
          return;
        }
      }
    }
    print('No writable characteristic found!');
  }

  Future<bool> sendCommand(String command) async {
    if (_writeCharacteristic == null) {
      print('Error: Write characteristic is null');
      return false;
    }

    try {
      final cmd = '${command}\n';
      final bytes = cmd.codeUnits;
      print('Sending command: $cmd (${bytes.length} bytes)');
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      print('Command sent successfully');
      return true;
    } catch (e) {
      print('Error sending command: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _writeCharacteristic = null;
    }
  }

  Future<void> reconnectLast() async {
    if (_lastDeviceId == null) return;

    final devices = await FlutterBluePlus.connectedDevices;
    for (final device in devices) {
      if (device.remoteId.str == _lastDeviceId) {
        _connectedDevice = device;
        await _discoverServices();
        return;
      }
    }
  }
}
