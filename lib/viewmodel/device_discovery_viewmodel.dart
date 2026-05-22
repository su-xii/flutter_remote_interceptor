import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/server/remote_server.dart';
import 'package:remote_interceptor/state/device_discovery_state.dart';
import 'package:remote_interceptor/model/device.dart';

class DeviceDiscoveryViewModel extends Notifier<DeviceDiscoveryState> {
  Timer? _debounceTimer;
  final List<Map<String, dynamic>> _pendingUpdates = [];
  bool _isProcessing = false;

  @override
  DeviceDiscoveryState build() {
    return DeviceDiscoveryState.initial();
  }

  Future<void> startScanning(RemoteServer server) async {
    if (state.isScanning) return;

    state = state.copyWith(isScanning: true);

    server.onDeviceFound = (String serverIp, int serverPort, String message) {
      _queueUpdate(serverIp, serverPort, message);
    };

    await server.startDeviceDiscovery();
  }

  void _queueUpdate(String serverIp, int serverPort, String message) {
    _pendingUpdates.add({
      'serverIp': serverIp,
      'serverPort': serverPort,
      'message': message,
    });

    if (!_isProcessing) {
      _processUpdates();
    }
  }

  Future<void> _processUpdates() async {
    _isProcessing = true;

    await Future.delayed(const Duration(milliseconds: 500));

    if (_pendingUpdates.isEmpty) {
      _isProcessing = false;
      return;
    }

    final latestUpdate = _pendingUpdates.last;
    _pendingUpdates.clear();

    try {
      _applyUpdate(
        latestUpdate['serverIp'] as String,
        latestUpdate['serverPort'] as int,
        latestUpdate['message'] as String,
      );
    } catch (e) {
      print('Error processing update: $e');
    }

    _isProcessing = false;
  }

  void _applyUpdate(String serverIp, int serverPort, String message) {
    final newDevices = Map<String, Device>.from(state.devices);
    final now = DateTime.now();

    if (newDevices.containsKey(serverIp)) {
      final existingDevice = newDevices[serverIp]!;
      final lastSeenDiff = now.difference(existingDevice.lastSeenTime).inSeconds;
      
      if (lastSeenDiff < 5) {
        return;
      }

      newDevices[serverIp] = existingDevice.copyWith(
        lastSeenTime: now,
      );
    } else {
      newDevices[serverIp] = Device(
        serverIp: serverIp,
        port: serverPort,
        info: message,
        lastSeenTime: now,
      );
    }

    state = state.copyWith(devices: newDevices);
  }

  void stopScanning(RemoteServer server) {
    _debounceTimer?.cancel();
    _pendingUpdates.clear();
    _isProcessing = false;
    state = state.copyWith(isScanning: false);

    if (server.onDeviceFound != null) {
      server.onDeviceFound = null;
    }

    server.stopDeviceDiscovery();
  }

  void connectToDevice(Device device, RemoteServer server) {
    server.connectToDevice(device.serverIp, device.port);
  }

  void clearDevices() {
    state = state.copyWith(devices: {});
  }
}
