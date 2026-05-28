import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers/providers.dart';
import 'package:remote_interceptor/mcp/mcp_server.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _startServers());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopServers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _stopServers();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _startServers() async {
    try {
      final remoteServer = ref.read(remoteServerProvider);
      await remoteServer.start();
      debugPrint('WS Server 已启动');
    } catch (e) {
      debugPrint('启动 WS Server 失败: $e');
    }

    try {
      final mcpServer = ref.read(mcpServerProvider);
      await mcpServer.start();
      debugPrint('MCP Server 已启动');
    } catch (e) {
      debugPrint('启动 MCP Server 失败: $e');
    }
  }

  Future<void> _stopServers() async {
    try {
      final remoteServer = ref.read(remoteServerProvider);
      await remoteServer.stop();
      debugPrint('WS Server 已停止');
    } catch (e) {
      debugPrint('停止 WS Server 失败: $e');
    }

    try {
      final mcpServer = ref.read(mcpServerProvider);
      await mcpServer.stop();
      debugPrint('MCP Server 已停止');
    } catch (e) {
      debugPrint('停止 MCP Server 失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
