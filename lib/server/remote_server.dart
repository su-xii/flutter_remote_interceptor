import 'dart:async';

import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';
import 'package:remote_interceptor/state/server_status_state.dart';

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
    // 非请求类消息（指令回执 / 预留的事件）：只回调与广播，不回包
    _server.eventHandler = (message) {
      eventHandler?.call(message);
      _eventController.add(message);
    };
    _server.onClientConnect = (){
      _clientConnectionStatus = ClientConnectionStatus.connected;
      _clientConnectController.add(());
    };
    _server.onClientDisconnect = ()=> onClientDisconnect?.call();
  }

  RequestHandler? requestHandler; // 请求处理

  /// 非请求类消息回调（`commandResult` 指令回执、预留的 `event`）
  void Function(Map<String, dynamic> message)? eventHandler;
  void Function()? onClientDisconnect; // 客户端断开连接回调
  // void Function()? onClientConnect; // 客户端断连接成功回调
  void Function()? onServerRunning;// 服务器启动成功回调
  void Function()? onServerStop;// 服务器停止回调

  ClientConnectionStatus _clientConnectionStatus = ClientConnectionStatus.disconnected;
  ServerStatus _serverStatus = ServerStatus.stopped;
  ClientConnectionStatus get clientConnectionStatus => _clientConnectionStatus;
  ServerStatus get serverStatus => _serverStatus;

  // 目前只有客户端连接成功需要多个地方回调
  final _clientConnectController = StreamController<()>.broadcast();
  // 对外提供订阅
  Stream<()> get onClientConnect => _clientConnectController.stream;

  // 非请求类消息（指令回执等）广播流，允许任意数量的 ViewModel 同时订阅
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  // 对外提供订阅
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  /// 向手机端主动下发指令（如跳转指令 `jump`）。
  /// fire-and-forget：不等待回执，回执通过 [events] 异步接收。
  void sendCommand(Map<String, dynamic> command) => _server.sendCommand(command);


  Future<void> start() async {
    await _server.start();
    _serverStatus = ServerStatus.running;
    onServerRunning?.call();
  }

  void disconnectClient() => _server.disconnectClient();

  Future<void> stop() async {
    await _server.stop();
    _clientConnectionStatus = ClientConnectionStatus.disconnected;
    onServerStop?.call();
  }
}
