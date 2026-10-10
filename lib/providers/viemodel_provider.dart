import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers/data_provider.dart';
import 'package:remote_interceptor/providers/providers.dart';
import 'package:remote_interceptor/state/response_edit_state.dart';
import 'package:remote_interceptor/viewmodel/response_edit_viewmodel.dart';

import '../state/device_discovery_state.dart';
import '../state/home_state.dart';
import '../state/mock_page_state.dart';
import '../state/mock_response_state.dart';
import '../state/server_status_state.dart';
import '../viewmodel/device_discovery_viewmodel.dart';
import '../viewmodel/home_viewmodel.dart';
import '../viewmodel/mock_page_viewmodel.dart';
import '../viewmodel/mock_response_viewmodel.dart';
import '../viewmodel/server_status_viewmodel.dart';

final serverStatusViewModelProvider =
    StateNotifierProvider<ServerStatusViewModel, ServerStatusState>(
  (ref) => ServerStatusViewModel(ref.read(remoteServerProvider)),
);

final homeViewModelProvider = StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
    return HomeViewModel(
        ref.read(remoteServerProvider),
        ref.watch(responseEditViewModelProvider.notifier).handleRequest,
        // 全局 Mock
        ref.watch(mockResponseViewModelProvider.notifier).handleRequest,
        // 页面级 Mock（与全局 Mock 互斥，由 HomeViewModel 按策略分派）
        ref.watch(mockPageViewModelProvider.notifier).handleRequest,
    );
});

final mockPageViewModelProvider = StateNotifierProvider.autoDispose<MockPageViewModel, MockPageState>((ref) {
    return MockPageViewModel(
        ref.read(mockPageStoreProvider),
        ref.read(remoteServerProvider),
    );
});


final responseEditViewModelProvider = StateNotifierProvider.autoDispose<ResponseEditViewModel, ResponseEditState>((ref) {
    return ResponseEditViewModel();
});

final deviceDiscoveryViewModelProvider = StateNotifierProvider.autoDispose<DeviceDiscoveryViewModel, DeviceDiscoveryState>((ref) {
    return DeviceDiscoveryViewModel(
        ref.read(deviceDiscoveryServerProvider),
        ref.read(remoteServerProvider),
        ref.read(deviceDiscoveryHistory)
    );
});

final mockResponseViewModelProvider = StateNotifierProvider.autoDispose<MockResponseViewModel, MockResponseState>((ref) {
    return MockResponseViewModel(
        ref.read(mockRuleStoreProvider)
    );
});