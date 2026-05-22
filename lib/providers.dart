import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/server/remote_server.dart';
import 'package:remote_interceptor/state/home_state.dart';
import 'package:remote_interceptor/state/device_discovery_state.dart';
import 'package:remote_interceptor/viewmodel/home_viewmodel.dart';
import 'package:remote_interceptor/viewmodel/device_discovery_viewmodel.dart';

final remoteServerProvider = Provider<RemoteServer>((ref) {
  return RemoteServer();
});

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(() {
  return HomeViewModel();
});

final deviceDiscoveryViewModelProvider = NotifierProvider<DeviceDiscoveryViewModel, DeviceDiscoveryState>(() {
  return DeviceDiscoveryViewModel();
});
