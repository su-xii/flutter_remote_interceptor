import '../model/device.dart';

/// 设备发现状态
class DeviceDiscoveryState {
  final bool isScanning;
  final bool isConnecting;
  final Map<String, Device> devices;
  final String? errorMessage;

  DeviceDiscoveryState({
    required this.isScanning,
    required this.isConnecting,
    required this.devices,
    this.errorMessage,
  });

  /// 初始状态
  factory DeviceDiscoveryState.initial() {
    return DeviceDiscoveryState(
      isScanning: false,
      isConnecting: false,
      devices: {},
    );
  }

  /// 获取在线设备
  List<Device> get onlineDevices {
    return devices.values.where((device) => device.isOnline).toList();
  }

  /// 创建副本
  DeviceDiscoveryState copyWith({
    bool? isScanning,
    bool? isConnecting,
    Map<String, Device>? devices,
    String? errorMessage,
  }) {
    return DeviceDiscoveryState(
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      devices: devices ?? this.devices,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
