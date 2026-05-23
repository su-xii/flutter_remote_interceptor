import '../model/device_model.dart';

/// 设备发现状态
class DeviceDiscoveryState {
  final bool isScanning;
  final bool isConnecting;
  final Map<String, DeviceModel> devices;
  final String? errorMessage;

  const DeviceDiscoveryState({
    required this.isScanning,
    required this.isConnecting,
    required this.devices,
    this.errorMessage,
  });

  /// 初始状态
  factory DeviceDiscoveryState.initial() {
    return DeviceDiscoveryState(
      isScanning: true,
      isConnecting: false,
      devices: {},
    );
  }

  /// 获取在线设备
  List<DeviceModel> get onlineDevices {
    return devices.values.where((device) => device.isOnline).toList();
  }

  /// 创建副本
  DeviceDiscoveryState copyWith({
    bool? isScanning,
    bool? isConnecting,
    Map<String, DeviceModel>? devices,
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
