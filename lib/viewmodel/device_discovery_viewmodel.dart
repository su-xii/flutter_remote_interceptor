import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/state/device_discovery_state.dart';
import 'package:remote_interceptor/model/device.dart';
import 'package:remote_interceptor/router/router_util.dart';

import '../providers.dart';
import '../state/server_state.dart';

class DeviceDiscoveryViewModel extends Notifier<DeviceDiscoveryState> {
  Timer? _debounceTimer;
  final List<Map<String, dynamic>> _pendingUpdates = [];
  bool _isProcessing = false;
  Function()? onConnectionSuccess;
  bool _initialized = false;

  @override
  DeviceDiscoveryState build() {
    final wsServer = ref.read(gWsServerProvider);
    wsServer.onClientStatusChanged = (status) {
      if (status == ClientConnectionStatus.connected && state.isConnecting) {
        state = state.copyWith(isConnecting: false);
        onConnectionSuccess?.call();
      }
    };
    
    return DeviceDiscoveryState.initial();
  }

  void onViewInit() {
    if (_initialized) return;
    _initialized = true;
    startScanning();
  }

  void onViewDispose() {
    cleanup();
  }

  Future<void> startScanning() async {
    if (state.isScanning) return;

    state = state.copyWith(isScanning: true);

    final discovery = ref.read(gDeviceDiscoveryProvider);
    discovery.onDeviceFound = (String serverIp, int serverPort, String message) {
      _queueUpdate(serverIp, serverPort, message);
    };

    await discovery.start();
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
      debugPrint('Error processing update: $e');
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

  void stopScanning() {
    _debounceTimer?.cancel();
    _pendingUpdates.clear();
    _isProcessing = false;
    state = state.copyWith(isScanning: false);

    final discovery = ref.read(gDeviceDiscoveryProvider);
    discovery.stop();
  }

  void connectToDevice(Device device) {
    state = state.copyWith(isConnecting: true);
    
    final discovery = ref.read(gDeviceDiscoveryProvider);
    discovery.sendConnectionRequest(device.serverIp, device.port);
  }

  void navigateToHome() {
    cleanup();
    RouterUtil.goToHome();
  }

  void clearDevices() {
    state = state.copyWith(devices: {});
  }

  void cleanup() {
    stopScanning();
  }
}
