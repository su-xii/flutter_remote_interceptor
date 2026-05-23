import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers.dart';

class Application extends ConsumerStatefulWidget {
  final Widget child;

  const Application({super.key, required this.child});

  @override
  ConsumerState<Application> createState() => _ApplicationState();
}

class _ApplicationState extends ConsumerState<Application> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWsServer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopWsServer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _stopWsServer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _startWsServer() async {
    try {
      final wsServer = ref.read(wsServerProvider);
      await wsServer.start();
      debugPrint('WS Server 已启动');
    } catch (e) {
      debugPrint('启动 WS Server 失败: $e');
    }
  }

  Future<void> _stopWsServer() async {
    try {
      final wsServer = ref.read(wsServerProvider);
      await wsServer.stop();
      debugPrint('WS Server 已停止');
    } catch (e) {
      debugPrint('停止 WS Server 失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
