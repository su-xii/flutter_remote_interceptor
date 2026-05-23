import 'dart:async';

import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';

class RemoteServer {
  // 远程响应服务
  final RemoteResponseServer _server = RemoteResponseServer();

  RemoteServer() {
    _server.requestHandler = (data) async {
      if (requestHandler != null) {
        data = await requestHandler!(data);
      }
      return data;
    };
    _server.onClientConnect = ()=> _clientConnectController.add(());
    _server.onClientDisconnect = ()=> onClientDisconnect?.call();
  }

  RequestHandler? requestHandler; // 请求处理
  void Function()? onClientDisconnect; // 客户端断开连接回调
  // void Function()? onClientConnect; // 客户端断连接成功回调
  void Function()? onServerRunning;// 服务器启动成功回调
  void Function()? onServerStop;// 服务器停止回调

  // 目前只有客户端连接成功需要多个地方回调
  final _clientConnectController = StreamController<void>.broadcast();
  // 对外提供订阅
  Stream<void> get onClientConnect => _clientConnectController.stream;


  Future<void> start() async {
    await _server.start();
    onServerRunning?.call();
  }

  void disconnectClient() => _server.disconnectClient();

  Future<void> stop() async {
    await _server.stop();
    onServerStop?.call();
  }
}
