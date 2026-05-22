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
  bool _isServerStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startServer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopServer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _stopServer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _startServer() async {
    if (_isServerStarted) return;

    try {
      final server = ref.read(remoteServerProvider);
      await server.start();
      _isServerStarted = true;
      debugPrint('RemoteServer 已启动');
    } catch (e) {
      debugPrint('启动 RemoteServer 失败: $e');
    }
  }

  Future<void> _stopServer() async {
    if (!_isServerStarted) return;

    try {
      final server = ref.read(remoteServerProvider);
      await server.stop();
      _isServerStarted = false;
      debugPrint('RemoteServer 已停止');
    } catch (e) {
      debugPrint('停止 RemoteServer 失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
