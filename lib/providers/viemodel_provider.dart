import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers/providers.dart';

import '../state/device_discovery_state.dart';
import '../state/home_state.dart';
import '../state/server_status_state.dart';
import '../viewmodel/device_discovery_viewmodel.dart';
import '../viewmodel/home_viewmodel.dart';
import '../viewmodel/server_status_viewmodel.dart';

final serverStatusViewModelProvider =
    StateNotifierProvider<ServerStatusViewModel, ServerStatusState>(
  (ref) => ServerStatusViewModel(ref.read(remoteServerProvider)),
);

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
    return HomeViewModel(
        ref.read(remoteServerProvider)
    );
});

final deviceDiscoveryViewModelProvider = StateNotifierProvider<DeviceDiscoveryViewModel, DeviceDiscoveryState>((ref) {
    return DeviceDiscoveryViewModel(
        ref.read(deviceDiscoveryServerProvider),
        ref.read(remoteServerProvider)
    );
});