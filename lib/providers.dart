import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/server/ws_server.dart';
import 'package:remote_interceptor/server/device_discovery.dart';
import 'package:remote_interceptor/state/home_state.dart';
import 'package:remote_interceptor/state/device_discovery_state.dart';
import 'package:remote_interceptor/viewmodel/home_viewmodel.dart';
import 'package:remote_interceptor/viewmodel/device_discovery_viewmodel.dart';

// 全局 Provider 变量
late final Provider<WsServer> gWsServerProvider;
late final Provider<DeviceDiscovery> gDeviceDiscoveryProvider;
late final NotifierProvider<HomeViewModel, HomeState> gHomeViewModelProvider;
late final NotifierProvider<DeviceDiscoveryViewModel, DeviceDiscoveryState> gDeviceDiscoveryViewModelProvider;

void initProviders() {
  gWsServerProvider = wsServerProvider;
  gDeviceDiscoveryProvider = deviceDiscoveryProvider;
  gHomeViewModelProvider = homeViewModelProvider;
  gDeviceDiscoveryViewModelProvider = deviceDiscoveryViewModelProvider;
}

final wsServerProvider = Provider<WsServer>((ref) {
  return WsServer();
});

final deviceDiscoveryProvider = Provider<DeviceDiscovery>((ref) {
  return DeviceDiscovery();
});

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(() {
  return HomeViewModel();
});

final deviceDiscoveryViewModelProvider = NotifierProvider<DeviceDiscoveryViewModel, DeviceDiscoveryState>(() {
  return DeviceDiscoveryViewModel();
});
