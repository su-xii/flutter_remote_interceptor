import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers.dart';

/// App 生命周期管理器
/// 负责监听 App 生命周期事件，并在 App 退出时释放资源
class AppLifecycleManager with WidgetsBindingObserver {
  final ProviderContainer _container;
  
  AppLifecycleManager(this._container) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        // 只有在 App 被销毁时才停止服务器
        _stopServer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // 其他状态不做处理，保持 Server 运行
        break;
    }
  }

  /// 停止服务器并释放资源
  Future<void> _stopServer() async {
    try {
      final server = _container.read(remoteServerProvider);
      await server.dispose();
      debugPrint('RemoteServer 已停止，资源已释放');
    } catch (e) {
      debugPrint('停止 RemoteServer 时出错: $e');
    }
  }

  /// 清理资源（在 App 完全退出时调用）
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _stopServer();
  }
}
