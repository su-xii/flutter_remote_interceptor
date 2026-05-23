import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/server/device_discovery_server.dart';
import 'package:remote_interceptor/server/remote_server.dart';
import 'package:remote_interceptor/state/device_discovery_state.dart';
import 'package:remote_interceptor/model/device_model.dart';
import 'package:remote_interceptor/router/router_util.dart';

import '../providers/providers.dart';

class DeviceDiscoveryViewModel extends StateNotifier<DeviceDiscoveryState> {

  final DeviceDiscoveryServer _deviceDiscoveryServer;
  final RemoteServer _remoteServer;
  late final StreamSubscription<void> _clientConnectSubscription;
  DeviceDiscoveryViewModel(this._deviceDiscoveryServer,this._remoteServer):super(DeviceDiscoveryState.initial()){
    _clientConnectSubscription = _remoteServer.onClientConnect.listen((_) => _clientConnected());
    _deviceDiscoveryServer.onDeviceFound = (serverIp, serverPort, message) {
      _queueUpdate(serverIp, serverPort, message);
    };
    _deviceDiscoveryServer.start();

  }

  @override
  void dispose() async{
    await _clientConnectSubscription.cancel();
    _deviceDiscoveryServer.stop();
    super.dispose();
  }

  // 客户端连接成功
  void _clientConnected() {
    state = state.copyWith(isConnecting: false);
    RouterUtil.goToHome();
  }

  void _queueUpdate(String serverIp, int serverPort, String message) {
    if(state.devices.containsKey(serverIp)){
      state = state.copyWith(devices: {
        serverIp: state.devices[serverIp]!..lastSeenTime = DateTime.now(),
        ...state.devices
      });
    }else{
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

}
