import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:remote_interceptor/server/remote_server.dart';
import 'package:remote_interceptor/viewmodel/home_viewmodel.dart';

// RemoteServer 作为全局单例，不随 Provider 销毁而销毁
final remoteServerProvider = Provider<RemoteServer>((_) {
  return RemoteServer();
});

// HomeViewModel 使用 ChangeNotifierProvider，当不再被监听时自动销毁
final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>((ref) {
  final server = ref.watch(remoteServerProvider);
  return HomeViewModel(server);
});