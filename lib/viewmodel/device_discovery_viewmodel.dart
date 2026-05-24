import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/data/local/device_discovery_history_store.dart';
import 'package:remote_interceptor/server/device_discovery_server.dart';
import 'package:remote_interceptor/server/remote_server.dart';
import 'package:remote_interceptor/state/device_discovery_state.dart';
import 'package:remote_interceptor/model/device_model.dart';
import 'package:remote_interceptor/router/router_util.dart';

class DeviceDiscoveryViewModel extends StateNotifier<DeviceDiscoveryState> {
  final DeviceDiscoveryServer _deviceDiscoveryServer;
  final RemoteServer _remoteServer;
  final DeviceDiscoveryHistoryStore _deviceDiscoveryHistoryStore;
  late final StreamSubscription<void> _clientConnectSubscription;
  // 手动插入的设备
  final Map<String, DeviceModel> _manualDevices = {};
  DeviceDiscoveryViewModel(this._deviceDiscoveryServer, this._remoteServer,this._deviceDiscoveryHistoryStore)
      : super(DeviceDiscoveryState.initial()) {
    _clientConnectSubscription =
        _remoteServer.onClientConnect.listen((_) => _clientConnected());
    _deviceDiscoveryServer.onDeviceFound = (serverIp, serverPort, message) {
      _queueUpdate(serverIp, serverPort, message);
    };
    _loadHistory();
    _deviceDiscoveryServer.start();
  }

  @override
  void dispose() async {
    await _clientConnectSubscription.cancel();
    _deviceDiscoveryServer.stop();
    _handleConnectedDevice();
    super.dispose();
  }

  // 加载历史记录
  void _loadHistory() async {
    final deviceIps = await _deviceDiscoveryHistoryStore.load();
    print("hhh $deviceIps");
    _manualDevices.addEntries(deviceIps.map((serverIp) => MapEntry(
        serverIp, DeviceModel(serverIp: serverIp, port: 0, info: ""))));
  }

  // 处理连接成功的设备
  void _handleConnectedDevice() {
    final deviceIps = state.devices.keys
        .where((serverIp) => _manualDevices.keys.contains(serverIp)).toList();
    _deviceDiscoveryHistoryStore.save(deviceIps);
  }

  // 客户端连接成功
  void _clientConnected() {
    state = state.copyWith(isConnecting: false);
    RouterUtil.goToHome();
  }

  void _queueUpdate(String serverIp, int serverPort, String message) {
    if (state.devices.containsKey(serverIp)) {
      state = state.copyWith(devices: {
        serverIp: state.devices[serverIp]!..lastSeenTime = DateTime.now(),
        ...state.devices
      });
    } else {
      state = state.copyWith(devices: {
        serverIp: DeviceModel(
          serverIp: serverIp,
          port: serverPort,
          info: message,
          lastSeenTime: DateTime.now(),
        ),
        ...state.devices
      });
    }
  }

  void connectToDevice(DeviceModel device) {
    state = state.copyWith(isConnecting: true);
    _deviceDiscoveryServer.sendConnectionRequest(device.serverIp, device.port);
  }

  // 添加设备
  void addDevice(
      {required String serverIp, required int port, required String info}) {
    _manualDevices[serverIp] = DeviceModel(
      serverIp: serverIp,
      port: port,
      info: info,
    );
    _deviceDiscoveryServer.manualDevices = _manualDevices;
  }
}
