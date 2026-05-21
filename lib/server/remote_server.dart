import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';

/// 服务端状态枚举
enum ServerStatus {
  starting,   // 服务启动中
  running,    // 服务运行中
  stopped,    // 服务已停止
}

/// 客户端连接状态
enum ClientConnectionStatus {
  disconnected,  // 客户端未连接
  connected,     // 客户端已连接
}

class RemoteServer {
  // 单例模式
  static final RemoteServer _instance = RemoteServer._internal();
  
  factory RemoteServer() {
    return _instance;
  }
  
  RemoteServer._internal();

  RequestHandler? requestHandler;

  DiscoveryClient? _discoveryClient;
  RemoteResponseServer? _server;
  bool _isDiscovered = false;
  bool _isStarted = false;
  
  // 服务器状态
  ServerStatus _status = ServerStatus.stopped;
  ServerStatus get status => _status;
  
  // 客户端连接状态
  ClientConnectionStatus _clientStatus = ClientConnectionStatus.disconnected;
  ClientConnectionStatus get clientStatus => _clientStatus;
  
  // 状态变化回调
  Function(ServerStatus)? onStatusChanged;
  Function(ClientConnectionStatus)? onClientStatusChanged;
  
  void _updateStatus(ServerStatus newStatus) {
    _status = newStatus;
    onStatusChanged?.call(newStatus);
  }
  
  void _updateClientStatus(ClientConnectionStatus newStatus) {
    _clientStatus = newStatus;
    onClientStatusChanged?.call(newStatus);
  }

  Future<void> start() async{
    if (_isStarted) return; // 防止重复启动
    
    try {
      _updateStatus(ServerStatus.starting);
      _updateClientStatus(ClientConnectionStatus.disconnected);
      
      _discoveryClient = DiscoveryClient();
      _server = RemoteResponseServer();
      _server!.requestHandler = (data) async{
        if (requestHandler != null) {
          data = await requestHandler!(data);
        }
        return data;
      };
      _server!.onClientDisconnect = (){
        _isDiscovered = false;
        _updateClientStatus(ClientConnectionStatus.disconnected);
        _discoveryClient?.start();
      };
      _server!.onClientConnect = (){
        if(!_isDiscovered) {
          _discoveryClient?.stop();
          _isDiscovered  = true;
          _updateStatus(ServerStatus.running);
          _updateClientStatus(ClientConnectionStatus.connected);
        }
      };
      
      await _discoveryClient!.start();
      await _server?.start();
      _isStarted = true;
      _updateStatus(ServerStatus.running);
    } catch (e) {
      _updateStatus(ServerStatus.stopped);
      _updateClientStatus(ClientConnectionStatus.disconnected);
      rethrow;
    }
  }

  Future<void> dispose() async{
    if (!_isStarted) return;
    
    await _server?.stop();
    _discoveryClient?.stop();
    _isStarted = false;
    _updateStatus(ServerStatus.stopped);
    _updateClientStatus(ClientConnectionStatus.disconnected);
  }

}