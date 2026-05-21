import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:remote_interceptor/model/device.dart';
import 'package:remote_interceptor/server/remote_server.dart';

class DeviceDiscoveryViewModel extends ChangeNotifier {
  final RemoteServer _server;
  
  // 设备列表（以 IP 为 key）
  final Map<String, Device> _devices = {};
  
  // 定时器，用于清理离线设备
  Timer? _cleanupTimer;
  
  // 是否正在扫描
  bool _isScanning = false;
  bool get isScanning => _isScanning;
  
  // 标记是否已销毁
  bool _disposed = false;
  
  // 获取在线设备列表（按最后发现时间排序）
  List<Device> get onlineDevices {
    final devices = _devices.values.where((d) => d.isOnline).toList();
    devices.sort((a, b) => b.lastSeenTime.compareTo(a.lastSeenTime));
    return devices;
  }
  
  // 获取所有设备列表
  List<Device> get allDevices {
    final devices = _devices.values.toList();
    devices.sort((a, b) => b.lastSeenTime.compareTo(a.lastSeenTime));
    return devices;
  }
  
  DeviceDiscoveryViewModel(this._server);
  
  /// 开始扫描设备
  void startScanning() {
    if (_isScanning) return;
    
    _isScanning = true;
    notifyListeners();
    
    // 设置设备发现回调
    _server.onDeviceFound = (String serverIp, int serverPort, String message) {
      if (_disposed) return; // 如果已销毁，不处理
      
      if (_devices.containsKey(serverIp)) {
        // 更新已存在设备的最后发现时间
        _devices[serverIp]!.lastSeenTime = DateTime.now();
      } else {
        // 添加新设备
        _devices[serverIp] = Device(
          serverIp: serverIp,
          port: serverPort,
          info: message,
          lastSeenTime: DateTime.now(),
        );
      }
      if (!_disposed) {
        notifyListeners();
      }
    };
    
    // 启动定期清理离线设备
    _cleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _removeOfflineDevices();
    });
    
    // 启动服务器端的设备发现
    _server.startDeviceDiscovery();
  }
  
  /// 停止扫描设备
  void stopScanning() {
    _isScanning = false;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    
    // 清除回调引用，防止页面销毁后仍然触发
    if (_server.onDeviceFound != null) {
      _server.onDeviceFound = null;
    }
    
    _server.stopDeviceDiscovery();
    if (!_disposed) {
      notifyListeners();
    }
  }
  
  /// 移除离线设备
  void _removeOfflineDevices() {
    if (_disposed) return; // 如果已销毁，不处理
    
    final now = DateTime.now().millisecondsSinceEpoch;
    _devices.removeWhere((key, device) {
      return now - device.lastSeenTime.millisecondsSinceEpoch >= 4000;
    });
    if (!_disposed) {
      notifyListeners();
    }
  }
  
  /// 连接到指定设备
  void connectToDevice(Device device) {
    _server.connectToDevice(device.serverIp, device.port);
  }
  
  /// 清除所有设备
  void clearDevices() {
    _devices.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _disposed = true;
    stopScanning();
    super.dispose();
  }
}
