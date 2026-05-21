import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/page/device_discovery_page.dart';
import 'package:remote_interceptor/providers.dart';
import 'package:remote_interceptor/app_lifecycle_manager.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 创建全局 ProviderContainer
  final container = ProviderContainer();
  
  // 启动 RemoteServer
  final server = container.read(remoteServerProvider);
  await server.start();
  
  // 初始化 App 生命周期管理器，传入 container
  final lifecycleManager = AppLifecycleManager(container);
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DeviceDiscoveryPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}