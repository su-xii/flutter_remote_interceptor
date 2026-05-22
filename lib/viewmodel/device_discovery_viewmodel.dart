import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/server/remote_server.dart';
import 'package:remote_interceptor/state/device_discovery_state.dart';
import 'package:remote_interceptor/model/device.dart';

class DeviceDiscoveryViewModel extends Notifier<DeviceDiscoveryState> {
  Timer? _debounceTimer;

  @override
  DeviceDiscoveryState build() {
    return DeviceDiscoveryState.initial();
  }

  void startScanning(RemoteServer server) {
    if (state.isScanning) return;

    state = state.copyWith(isScanning: true);

    server.onDeviceFound = (String serverIp, int serverPort, String message) {
      _updateDevice(serverIp, serverPort, message);
    };

    server.startDeviceDiscovery();
  }

  void _updateDevice(String serverIp, int serverPort, String message) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
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
    });
  }

  void stopScanning(RemoteServer server) {
    _debounceTimer?.cancel();
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
